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

contract Coin is
    ERC1155,
    Ownable,
    ERC1155Burnable,
    ERC1155Supply,
    ReentrancyGuard
{
    uint256 private constant COIN = 1;
    string public ipfsURI;
    address Trunk1Address;
    mapping(uint256 => bool) private processedChunksForAirdrop;

    constructor() ERC1155("") {}

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, COIN, amount, "");
    }

    function setTrunk1Address(address _trunk1Address) external onlyOwner {
        Trunk1Address = _trunk1Address;
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
            balanceOf(receivers[0], COIN) > 0
        ) revert ChunkAlreadyProcessed();

        for (uint256 i; i < receivers.length; ) {
            mint(receivers[i], numTokens[i]);
            unchecked {
                ++i;
            }
        }
        processedChunksForAirdrop[chunkNum] = true;
    }

    /**
     * @dev Called by trunk1 contract upon burning
     */
    function mintFromBurn(uint256 _amount, address _caller) external {
        require(
            msg.sender == Trunk1Address,
            "Only can be called from trunk1 contract"
        );
        require(tx.origin == _caller, "Only can be called by owner");
        _mint(_caller, COIN, _amount, "");
    }

    function burnExternal(uint256 _amount, address _caller) external {
        require(
            tx.origin == _caller,
            "Cannot burn tokens that do not belong to you"
        );
        _burn(_caller, COIN, _amount);
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

interface TrunkInterface {
    function burnExternal(uint256 _amount, address _caller) external;
}