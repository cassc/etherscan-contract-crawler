// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/// @title Spread NFT Dapp, ERC721 Edition Ethereum.
/// @author @dadogg80, Viken Blockchain Solutions.
/// @notice Transfer your NFT's to multiple accounts in one transaction.
/// @dev The purpose of this smart-contract was to create an smart contract that would allow us to transfer a batch of ntf's to multiple accounts.


contract BatchTransferNft is Ownable {
    
    uint256 fee = 0.005 ether;

    /// @dev authentication error.
    error Error_1();

    /// @dev thrown by receive function.
    error Error_2();


    /// @dev thrown if zero values.
    error ZeroValues();
    error LowValue(string message);

    event TransferID(uint Id);
    
    constructor() {
    }

    modifier noZeroValues(address[] calldata recipients, uint256[][] calldata ids) {
      if (recipients.length <= 0 ||  ids.length <= 0) revert ZeroValues();
      _;
    }

    modifier noZeroValuesERC20(address[] calldata recipients, uint256[] calldata values) {
      if (recipients.length <= 0 ||  values.length <= 0) revert ZeroValues();
      _;
    }

    modifier costs() {
      if (msg.value < fee) revert LowValue("Add min 0.005 ether");
      _;
    }

    /// @dev Receive function.
    receive() external payable {
        revert Error_2();
    } 

    /// This will allow you to batch transfer and send multiple nfts to multiple accounts.
    /// @param collection The collection to transfer from.
    /// @param recipients List with the recipient accounts.
    /// @param ids A List of lists, with the tokenIds to transfer to the corresponding recipient.
    /// @dev Address example: ["address","address","address"].
    /// @dev ids example: [[tokenId,tokenId][tokenId,tokenId],[tokenId,tokenId]].
    /// @dev requires setApprovalForAll(operator, true)
    function spreadERC721(IERC721 collection, address[] calldata recipients, uint256[][] calldata ids) 
        external 
        payable 
        costs()
        noZeroValues(  
            recipients, 
            ids
        ) 
    {
        for (uint256 i = 0; i < recipients.length; i++) {
            uint256[] memory _ids = ids[i];
            for(uint256 k = 0; k < _ids.length; k++) {
                collection.safeTransferFrom(_msgSender(), recipients[i], _ids[k], "");
                emit TransferID(_ids[k]);
            }
        }
    }

    /// This will allow you to batch transfers of erc20 tokens, to multiple accounts.
    /// @param token The ERC20 contract address
    /// @param recipients List with the recipient accounts.
    /// @param values List with values to transfer to the corresponding recipient.
    /// @dev Address example: ["address","address","address"].
    /// @dev Value example: [value,value,value].
    function spreadERC20(IERC20 token, address[] calldata recipients, uint256[] calldata values) external noZeroValuesERC20(recipients, values) {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values[i];
        token.transferFrom(_msgSender(), address(this), total);
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values[i]));
    }

    /// This is a cheaper way to batch transfer erc20 tokens, to multiple accounts.
    /// @param token The ERC20 contract address
    /// @param recipients List with the recipient accounts.
    /// @param values List with values to transfer to the corresponding recipient.
    /// @dev Address example: ["address","address","address"].
    /// @dev Value example: [value, value, value].
    function spreadERC20Simple(IERC20 token, address[] calldata recipients, uint256[] calldata values) external noZeroValuesERC20(recipients, values) {
        for (uint256 i = 0; i < recipients.length; i++)
            token.transferFrom(_msgSender(), recipients[i], values[i]);
    }

    /// This will allow the owner account to save any stuck erc20 tokens.
    /// @param collection The ERC721 collection contract address.
    /// @param ids List with the tokenIds to transfer to the corresponding recipient.
    /// @dev Restricted by onlyOwner modifier.
    function saveERC721(IERC721 collection, uint256[][] calldata ids) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            uint256[] memory _ids = ids[i];
            for(uint256 k = 0; k < _ids.length; k++) {
                collection.transferFrom(address(this), _msgSender(), _ids[k]);
                emit TransferID(_ids[k]);
            }
        }
    }
    
    /// This will allow the owner account to save any stuck erc20 tokens.
    /// @param token The ERC20 contract address.
    /// @dev Restricted by onlyOwner modifier.
    function saveERC20(IERC20 token) external onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        token.transfer(address(_msgSender()), amount);
    }

    /// This will allow the owner account to save any stuck main asset.
    /// @dev Restricted by onlyOwner modifier.
    function saveAsset() external onlyOwner {
        uint256 asset = address(this).balance;
        payable(_msgSender()).transfer(asset);
    }
}