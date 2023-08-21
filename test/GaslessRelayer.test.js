let GaslessRelayer = artifacts.require("GaslessRelayer");
let SimpleStorage = artifacts.require("SimpleStorage");
const ethers = require("ethers");
contract("GaslessRelayer", (accounts) => {
  let owner = accounts[0];

  let nonce = 0; //Need to find a better way to work with nonce

  let wallet = ethers.Wallet.createRandom();
  let signer = wallet.address;
  let signerPrivateKey = wallet.privateKey;

  let gaslessRelayer, simpleStorage;

  console.log("Starting GaslessRelayer test...");

  beforeEach(async () => {
    // Deploy SimpleStorage contract
    simpleStorage = await SimpleStorage.new({ from: owner });
    console.log("SimpleStorage contract deployed:", simpleStorage.address);

    // Deploy GaslessRelayer contract with the owner's address and a default gas price
    gaslessRelayer = await GaslessRelayer.new(
      web3.utils.toWei("100000", "gwei"), // if needecany
      { from: owner }
    );
    console.log("GaslessRelayer contract deployed:", gaslessRelayer.address);
  });

  it("Relay transaction using GaslessRelayer contract", async () => {
    // Get the nonce for the signer
    console.log(`Nonce for signer ${signer}: ${nonce}`);

    const setDataValue = 200;
    const data = web3.eth.abi.encodeFunctionCall(
      simpleStorage.abi.find((e) => e.name === "setData"),
      [setDataValue, signer]
    );

    // add signer to whitelist
    console.log(
      "If signer is wlbefore adding:",
      await gaslessRelayer.wlAddress(signer)
    );
    let addToWhitelist = await gaslessRelayer.addToWhitelist(signer);
    console.log(
      "If signer whitelisted:",
      await gaslessRelayer.wlAddress(signer)
    );
    // Get the data hash from the contract
    let dataHash = await gaslessRelayer.getDataHash(data);
    console.log(`Data hash from contract: ${dataHash}`);

    // Calculate the data hash locally
    let localDataHash = web3.utils.keccak256(data);
    console.log(`Local data hash: ${localDataHash}`);

    // Check if the data hashes are equal
    assert.equal(dataHash, localDataHash, "Data hashes are not equal");

    // Prepare the message for the transaction
    let messageHash = await gaslessRelayer.getMsgHash(
      simpleStorage.address,
      data,
      nonce
    );
    console.log(`Message hash from contract: ${messageHash}`);

    // Calculate the message hash locally
    let encodedParams = ethers.utils.solidityPack(
      ["address", "bytes", "uint256"],
      [simpleStorage.address, data, nonce]
    );
    let messageHashBySigner = ethers.utils.keccak256(encodedParams);
    console.log(`Local message hash: ${messageHashBySigner}`);

    // Check if the message hashes are equal
    assert.equal(
      messageHash,
      messageHashBySigner,
      "Message hashes are not equal"
    );

    // Sign the message using signer's account
    let signature = web3.eth.accounts.sign(
      messageHashBySigner,
      signerPrivateKey
    )
    console.log(signature)
    

    let newData = await simpleStorage.data_a();
    console.log(
      "Value of data_a before validating signature:",
      newData.toString()
    );

    // Relay the transaction using the GaslessRelayer contract
    /**
     * @param signature.v The recovery id (part of the signature) a single byte value that indicates the the y-coordinate parity of the public key.
     * @param signature.r The output of the ECDSA signature's "r" a 32-byte value representing the x-coordinate of the public key.
     * @param signature.s The output of the ECDSA signature's "s" a 32-byte value representing a scalar value.
     */
    try {
      console.log("Relaying transaction...");
      let relayTrx = await gaslessRelayer.relay(
        simpleStorage.address,
        data,
        nonce,
        signature.signature,
        signature.messageHash,
        messageHashBySigner,
        { from: owner }
      );
      console.log(
        "Realy Transaction Executed with hash",
        relayTrx.receipt.transactionHash
      );
      nonce++;
    } catch (error) {
      console.error("Transaction reverted:", error.reason || error.message);

      if(error.reason || error.message=="INVALID_SIGNER"){
        console.log("Add the signer to wl from line 44 in the code with function name addToWhitelist")
      }
    }

    newData = await simpleStorage.data_a();
    console.log("New value of data_a:", newData.toString());
    // console.log("New value of data_a:",await gaslessRelayer.getMessageHashFromSignature(signature.signature));

    // Get the final balances
    let finalSignerBalance = await web3.eth.getBalance(signer);
    let finalOwnerBalance = await web3.eth.getBalance(owner);

    console.log(`Final Signer Balance: ${signer} ${finalSignerBalance} gwei`);
    console.log(`Final Owner Balance: ${owner} ${finalOwnerBalance} gwei`);
    console.log("Test completed.");
  });
});
