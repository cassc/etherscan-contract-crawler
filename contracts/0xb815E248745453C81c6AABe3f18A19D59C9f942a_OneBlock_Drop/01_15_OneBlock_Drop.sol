// SPDX-License-Identifier: MIT

//  ██╗██████╗ ██╗      ██████╗  ██████╗██╗  ██╗
// ███║██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝
// ╚██║██████╔╝██║     ██║   ██║██║     █████╔╝
//  ██║██╔══██╗██║     ██║   ██║██║     ██╔═██╗
//  ██║██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗
//  ╚═╝╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
//
//         ██████╗ ██████╗  ██████╗ ██████╗
//         ██╔══██╗██╔══██╗██╔═══██╗██╔══██╗
//         ██║  ██║██████╔╝██║   ██║██████╔╝
//         ██║  ██║██╔══██╗██║   ██║██╔═══╝
//         ██████╔╝██║  ██║╚██████╔╝██║
//         ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./MintContractInterface.sol";

/**
 * @dev Implementation of the MS tokens which are ERC1155 tokens.
 */
contract OneBlock_Drop is
    ERC1155,
    ERC1155Burnable,
    ReentrancyGuard,
    Ownable,
    ERC2981
{
    /**
     * @dev The name of token.
     */
    string public name = "1B_Drop";

    /**
     * @dev The name of token symbol.
     */
    string public symbol = "OBD";

    /**
     * @dev The owner can toggle the 'isBurnToMintActive' state.
     */
    bool public isBurnToMintActive;

    /**
     * @dev The token URI per token id.
     */
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev The mint contract interface per token id after burning.
     */
    mapping(uint256 => MintContractInterface) public mintContracts;

    /**
     * @dev Constractor of MetaSamuraiAirdrop contract. Setting the royalty info.
     */
    constructor() ERC1155("") {
        setRoyaltyInfo(_msgSender(), 750); // 750 == 7.5%
    }

    /**
     * @dev For receiving ETH just in case someone tries to send it.
     */
    receive() external payable {}

    /**
     * @dev Airdrop the number of MS tokens to '_receivers'.
     * @param _receivers Addresses of the receivers.
     * @param _mintAmounts Numbers of the mints.
     * @param _tokenId Airdrop's token id.
     */
    function airdrop(
        address[] calldata _receivers,
        uint256[] calldata _mintAmounts,
        uint256 _tokenId
    ) external onlyOwner {
        uint256 receiverAmount = _receivers.length;

        require(
            receiverAmount == _mintAmounts.length,
            "MSA: Length doesn't match."
        );
        for (uint256 i = 0; i < receiverAmount; ) {
            _mint(_receivers[i], _tokenId, _mintAmounts[i], "");
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Burn own NFTs and mint new ones. Call this function after calling 'setMintContract'.
     * @param _tokenId Token id for burning and associates with 'mintContracts' to mint.
     * @param _amount Numbers of burning own NFTs and minting new ones.
     */
    function burnToMint(uint256 _tokenId, uint256 _amount)
        external
        nonReentrant
    {
        require(isBurnToMintActive, "MSA: burnToMint is not active yet");
        address caller = _msgSender();
        require(caller == tx.origin, "MSA: Cannot be called by contract");
        _burn(caller, _tokenId, _amount);
        mintContracts[_tokenId].mintFromBurn(_amount, caller);
    }

    /**
     * @dev Specify the token id and set the new token URI to '_tokenURIs'.
     */
    function setURI(uint256 _tokenId, string memory _newTokenURI)
        external
        onlyOwner
    {
        _tokenURIs[_tokenId] = _newTokenURI;
    }

    /**
     * @dev Set the minting contract.
     */
    function setMintContract(uint256 _tokenId, address _contractAddress)
        external
        onlyOwner
    {
        mintContracts[_tokenId] = MintContractInterface(_contractAddress);
    }

    /**
     * @dev Toggle the 'isBurnToMintActive'.
     */
    function toggleBurnToMintActive() external onlyOwner {
        isBurnToMintActive = !isBurnToMintActive;
    }

    /**
     * @notice Only the owner can withdraw all of the contract balance.
     * @dev All the balance transfers to the owner's address.
     */
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "MSA: withdraw is failed!!");
    }

    /**
     * @dev Set the new royalty fee and the new receiver.
     */
    function setRoyaltyInfo(address _receiver, uint96 _royaltyFee)
        public
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _royaltyFee);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Return tokenURI for the specified token ID.
     * @param _tokenId The token ID the token URI is returned for.
     */
    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return _tokenURIs[_tokenId];
    }
}