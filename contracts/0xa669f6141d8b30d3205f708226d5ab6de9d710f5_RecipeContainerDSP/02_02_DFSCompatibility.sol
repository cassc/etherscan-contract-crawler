// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;


/// @dev List of actions grouped as a recipe
/// @param name Name of the recipe useful for logging what recipe is executing
/// @param callData Array of calldata inputs to each action
/// @param subData Used only as part of strategy, subData injected from StrategySub.subData
/// @param actionIds Array of identifiers for actions - bytes4(keccak256(ActionName))
/// @param paramMapping Describes how inputs to functions are piped from return/subbed values
struct Recipe {
    string name;
    bytes[] callData;
    bytes32[] subData;
    bytes4[] actionIds;
    uint8[][] paramMapping;
}

struct ParamsPull {
    address tokenAddr;
    address from;
    uint256 amount;
}

struct ParamsSend {
    address tokenAddr;
    address to;
    uint256 amount;
}

interface IDSProxy {
    function execute(
        address _targetAddress,
        bytes calldata _data
    ) external payable returns (bytes32);

    function setOwner(address _newOwner) external;
}

interface IProxyRegistry {
    function build(address owner) external returns (IDSProxy proxy);
}

interface IRegistry {
    function getAddr(bytes4) external view returns (address);
    function isRegistered(bytes4) external view returns (bool);
}

interface IPullAction{
    function parseInputs(bytes memory _callData) external pure returns (ParamsPull memory params);
}

interface ISendAction{
    function parseInputs(bytes memory _callData) external pure returns (ParamsSend memory params);
}

function registerDFS()
    view
    returns 
    (
    address recipeExecutor,
    address dfsRegistryAddress
    ) 
{
        if (block.chainid == 1) {
            recipeExecutor = 0xe822d76c2632FC52f3eaa686bDA9Cea3212579D8;
            dfsRegistryAddress = 0x287778F121F134C66212FB16c9b53eC991D32f5b;
        } else if (block.chainid == 10){
            recipeExecutor = 0xe91ff198bA6DFA97A7B4Fa43e5a606c915B0471f;
            dfsRegistryAddress = 0xAf707Ee480204Ed6e2640B53cE86F680D28Afcbd;
        }
}