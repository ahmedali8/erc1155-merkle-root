import { DeployFunction, DeployResult } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

import { preDeploy } from "../utils/contracts";
import { toWei } from "../utils/format";
import { verifyContract } from "../utils/verify";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, getChainId, deployments } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  await preDeploy({
    signerAddress: deployer,
    contractName: "TestUSDT",
  });
  const usdtDeployResult = await deploy("TestUSDT", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [],
    log: true,
    // waitConfirmations: 5,
  });

  const USDT_CONTRACT = usdtDeployResult.address;
  const WALLET_ADDRESS = deployer;

  const CONTRACT_NAME = "Token";
  await preDeploy({ signerAddress: deployer, contractName: CONTRACT_NAME });
  const tokenDeployResult: DeployResult = await deploy(CONTRACT_NAME, {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [USDT_CONTRACT, WALLET_ADDRESS],
    log: true,
    // waitConfirmations: 5,
  });

  // You don't want to verify on localhost
  try {
    if (chainId !== "31337" && chainId !== "1337") {
      const contractPath = `contracts/${CONTRACT_NAME}.sol:${CONTRACT_NAME}`;
      await verifyContract({
        contractPath: contractPath,
        contractAddress: tokenDeployResult.address,
        args: tokenDeployResult.args || [],
      });
    }
  } catch (error) {
    console.log(error);
  }
};

export default func;
func.tags = ["Token"];
