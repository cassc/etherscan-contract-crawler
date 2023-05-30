// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error ChunkAlreadyProcessed();
error MismatchedArrays();

contract Trunk1 is
    ERC1155,
    Ownable,
    ERC1155Burnable,
    ERC1155Supply,
    ReentrancyGuard
{
    uint256 public constant TRUNK_1 = 1;
    address public merchPassContract;
    address public coinContract;
    address public trunk2Contract;
    string public ipfsURI = "";
    mapping(uint256 => bool) private processedChunksForAirdrop;

    constructor() ERC1155("") {}

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, TRUNK_1, amount, "");
    }

    function airdrop(
        address[] calldata receivers,
        uint256[] calldata numTokens,
        uint256 chunkNum
    ) external onlyOwner {
        if (receivers.length != numTokens.length || receivers.length == 0)
            revert MismatchedArrays();
        if (
            processedChunksForAirdrop[chunkNum] ||
            balanceOf(receivers[0], TRUNK_1) > 0
        ) revert ChunkAlreadyProcessed();

        for (uint256 i; i < receivers.length; ) {
            mint(receivers[i], numTokens[i]);
            unchecked {
                ++i;
            }
        }
        processedChunksForAirdrop[chunkNum] = true;
    }

    function setMerchPassContract(address _contract) public onlyOwner {
        merchPassContract = _contract;
    }

    function setCoinContract(address _contract) public onlyOwner {
        coinContract = _contract;
    }

    function setTrunk2Contract(address _contract) public onlyOwner {
        trunk2Contract = _contract;
    }

    /**
     * @dev Called when burning trunk 1 to mint merch pass, coin and trunk 2
     */
    function burnToMint(uint256 _amount) external {
        require(msg.sender == tx.origin, "Cannot be called by contract");
        _burn(msg.sender, TRUNK_1, _amount);
        MerchPassInterface(merchPassContract).mintFromBurn(_amount, msg.sender);
        CoinInterface(coinContract).mintFromBurn(_amount, msg.sender);
        Trunk2Interface(trunk2Contract).mintFromBurn(_amount, msg.sender);
    }

    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return ipfsURI;
    }

    function setURI(string calldata _uri) external onlyOwner {
        ipfsURI = _uri;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

interface MerchPassInterface {
    function mintFromBurn(uint256 _amount, address _caller) external;
}

interface CoinInterface {
    function mintFromBurn(uint256 _amount, address _caller) external;
}

interface Trunk2Interface {
    function mintFromBurn(uint256 _amount, address _caller) external;
}