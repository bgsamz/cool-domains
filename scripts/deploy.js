const main = async () => {
  const domainContractFactory = await hre.ethers.getContractFactory('Domains');
  const domainContract = await domainContractFactory.deploy("mus");
  await domainContract.deployed();

  console.log("Contract deployed to:", domainContract.address);

  let txn = await domainContract.register("twice",  {value: hre.ethers.utils.parseEther('0.1')});
  await txn.wait();
  console.log("Minted domain twice.mus");

  txn = await domainContract.setRecord("twice", 'https://open.spotify.com/track/2qQpFbqqkLOGySgNK8wBXt');
  await txn.wait();
  console.log("Set record for twice.mus");

  const address = await domainContract.getAddress("twice");
  console.log("Owner of domain twice:", address);

  const balance = await hre.ethers.provider.getBalance(domainContract.address);
  console.log("Contract balance:", hre.ethers.utils.formatEther(balance));
}

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();