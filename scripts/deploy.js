async function main() {
    console.log("Going to deploy the contract now");

    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account :: ", deployer.address);

    const LotteryCF = await ethers.getContractFactory("Lottery");
    const Lottery = await LotteryCF.deploy();

    console.log("Contract deployed, interact at :: ", Lottery.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
