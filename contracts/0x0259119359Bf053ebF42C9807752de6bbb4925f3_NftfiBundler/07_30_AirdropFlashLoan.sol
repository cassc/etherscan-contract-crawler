// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title AirdropFlashLoan
 * @author NFTfi
 * @dev
 */
contract AirdropFlashLoan is ERC721Holder, ERC1155Holder, ReentrancyGuard {
    using Address for address;
    using SafeERC20 for IERC20;

    /**
     * @notice this function initiates a flashloan to pull an airdrop from a tartget contract
     *
     * @param _nftContract - contract address of the target nft of the drop
     * @param _nftId - id of the target nft of the drop
     * @param _target - address of the airdropping contract
     * @param _data - function selector to be called on the airdropping contract
     * @param _nftAirdrop - address of the used claiming nft in the drop
     * @param _nftAirdropId - id of the used claiming nft in the drop
     * @param _is1155 -
     * @param _nftAirdropAmount - amount in case of 1155
     * @param _beneficiary - address receiving the drop
     */
    function pullAirdrop(
        address _nftContract,
        uint256 _nftId,
        address _target,
        bytes calldata _data,
        address _nftAirdrop,
        uint256 _nftAirdropId,
        bool _is1155,
        uint256 _nftAirdropAmount,
        address _beneficiary
    ) external nonReentrant {
        // assumes that the collateral nft has been transferreded to this contract before calling this function
        _target.functionCall(_data);

        // return the collateral
        IERC721(_nftContract).approve(msg.sender, _nftId);

        // in case that arbitray function from _target does not send the airdrop to a specified address
        if (_nftAirdrop != address(0) && _beneficiary != address(0)) {
            // send the airdrop to the beneficiary
            if (_is1155) {
                IERC1155(_nftAirdrop).safeTransferFrom(
                    address(this),
                    _beneficiary,
                    _nftAirdropId,
                    _nftAirdropAmount,
                    "0x"
                );
            } else {
                IERC721(_nftAirdrop).safeTransferFrom(address(this), _beneficiary, _nftAirdropId);
            }
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC1155Receiver) returns (bool) {
        return _interfaceId == type(IERC721Receiver).interfaceId || super.supportsInterface(_interfaceId);
    }
}