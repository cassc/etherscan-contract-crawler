// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./interfaces/IMetaSportsNFTETH.sol";

contract MSNFTCrossToETH is
    ERC721Holder,
    Ownable,
    Pausable,
    ReentrancyGuard,
    AccessControl
{
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    bytes32 public constant TRAN_OUT_ROLE = keccak256("TRAN_OUT_ROLE");
    IMetaSportsNFTETH public immutable MS_ETH_NFT;
    address public adminAddress;
    uint256 public crossChainFee = 0.005 ether;

    // Set of tokenIds for a address
    mapping(address => EnumerableSet.UintSet) private pendingTokenIds;

    event TransferIn(address indexed seller, uint256[] tokenIds);
    event TransferOut(address indexed recipient, uint256[] tokenIds);

    constructor(address _collectionAddress) {
        require(
            _collectionAddress != address(0),
            "NFT collection address can not be zero"
        );
        MS_ETH_NFT = IMetaSportsNFTETH(_collectionAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TRAN_OUT_ROLE, msg.sender);
    }

    function setCrossChainFee(uint256 _crossChainFee) external onlyOwner{
        crossChainFee = _crossChainFee;
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    modifier needCheck(uint256[] memory _tokenIds) {
        require(_tokenIds.length > 0, "TokenIds length can not be 0");
        require(
            checkTokenIdOwner(_tokenIds),
            "The NFT is not belong to the address"
        );
        require(
            checkTokenIdRepeat(_tokenIds),
            "The tokenIds contains duplicates"
        );
        require(checkCrossChainFee(_tokenIds), "Insufficient cross chain fee");
        _;
    }

    function checkTokenIdRepeat(uint256[] memory _tokenIds)
        private
        pure
        returns (bool)
    {
        for (uint i = 0; i < _tokenIds.length; i++) {
            for (uint j = i + 1; j < _tokenIds.length; j++) {
                if (_tokenIds[i] == _tokenIds[j]) {
                    return false;
                }
            }
        }
        return true;
    }

    function checkTokenIdOwner(uint256[] memory _tokenIds)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (MS_ETH_NFT.ownerOf(_tokenIds[i]) != msg.sender) {
                return false;
            }
        }
        return true;
    }

    function checkCrossChainFee(uint256[] memory _tokenIds)
        private
        view
        returns (bool)
    {
        uint256 totalFee;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            totalFee += crossChainFee;
        }
        if (msg.value < totalFee) {
            return false;
        }
        return true;
    }

    function getPendingTokenIds(address _user)
        public
        view
        returns (uint256[] memory tokenIds)
    {
        return pendingTokenIds[_user].values();
    }

    function removePendingTokenIds(address _user, uint256[] memory _tokenIds)
        external
        onlyRole(TRAN_OUT_ROLE)
    {
        require(
            checkTokenIdRepeat(_tokenIds),
            "The tokenIds contains duplicates"
        );
        require(pendingTokenIds[_user].length() > 0, "No");
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(
                pendingTokenIds[_user].contains(_tokenIds[i]),
                "There is not the tokenId"
            );
        }
        for (uint i = 0; i < _tokenIds.length; i++) {
            pendingTokenIds[_user].remove(_tokenIds[i]);
        }
    }

    function transferIn(uint256[] memory _tokenIds)
        external
        payable
        needCheck(_tokenIds)
        whenNotPaused
        nonReentrant
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            MS_ETH_NFT.safeTransferFrom(
                msg.sender,
                address(this),
                _tokenIds[i]
            );
            pendingTokenIds[msg.sender].add(_tokenIds[i]);
        }
        emit TransferIn(msg.sender, _tokenIds);
    }

    function transferOut(address _recipient, uint256[] calldata _tokenIds)
        external
        onlyRole(TRAN_OUT_ROLE)
        whenNotPaused
        nonReentrant
    {
        require(_recipient != address(0), "Receive address can not be zero");
        require(
            checkTokenIdRepeat(_tokenIds),
            "The tokenIds contains duplicates"
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            if (!MS_ETH_NFT.exisit(tokenId)) {
                MS_ETH_NFT.safeMint(_recipient, tokenId);
            } else {
                require(
                    MS_ETH_NFT.ownerOf(tokenId) == address(this),
                    "The NFT is not belong to the address"
                );
                MS_ETH_NFT.safeTransferFrom(address(this), _recipient, tokenId);
            }
        }
        emit TransferOut(_recipient, _tokenIds);
    }

    function withdraw() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            Address.sendValue(payable(owner()), balance);
        }
    }

    function withdrawERC20(address _tokenContract)
        external
        onlyOwner
        nonReentrant
    {
        uint256 balance = IERC20(_tokenContract).balanceOf(address(this));
        if (balance > 0) {
            IERC20(_tokenContract).safeTransfer(owner(), balance);
        }
    }
}