// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./interface/ICollats.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @custom:security-contact [email protected]
contract CollatsNFTVault is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    //NFT Contrat's Address, NFT Id, Amount of Collats
    mapping(address => mapping(uint256 => uint256)) private _balances;
    uint256 public collatsInVault;
    ICollats public collats;

    event CollatsWithdraw(
        address indexed to,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 balance
    );
    event CollatsAdded(
        address indexed from,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 balance
    );

    function initialize(address _collats) external initializer {
        __Ownable_init();
        collats = ICollats(_collats);
    }

    function buyAndAddCollats(address nftAddress, uint256 tokenId)
        public
        payable
        returns (uint256 collatsBought)
    {
        collatsBought = collats.buyCollats{value: msg.value}();
        _addCollats(nftAddress, tokenId, collatsBought);
    }

    function buyAndAddCollatsWithERC20(
        address nftAddress,
        uint256 tokenId,
        address token,
        uint256 amount
    ) public returns (uint256 collatsBought) {
        if (token == address(collats)) {
            addCollats(nftAddress, tokenId, amount);
            return amount;
        }
        //do the safeTransferFrom the sender
        IERC20Upgradeable(token).safeTransferFrom(
            _msgSender(),
            address(this),
            amount
        );
        //do the approval for the Collats Contract
        IERC20Upgradeable(token).safeApprove(address(collats), amount);
        //Call buyCollatsWithERC20 and get the amount of Collats bought
        collatsBought = collats.buyCollatsWithERC20(token, amount);
        _addCollats(nftAddress, tokenId, collatsBought);
    }

    function addCollats(
        address nftAddress,
        uint256 tokenId,
        uint256 amount
    ) public {
        // require(
        collats.transferFrom(_msgSender(), address(this), amount);
        //     "CollatsNftVault: Failed to receive the amount"
        // );
        _addCollats(nftAddress, tokenId, amount);
    }

    function addCollatsInBulk(
        address[] memory nftAddresses,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) public {
        require(
            nftAddresses.length > 0 &&
                nftAddresses.length == tokenIds.length &&
                tokenIds.length == amounts.length,
            "CollatsNftVault: quantities don't match"
        );
        //Add all the quantities together for a single transfer and reduced gas fees.
        uint256 pooledAmount = poolAmounts(amounts);
        require(
            collats.transferFrom(_msgSender(), address(this), pooledAmount),
            "CollatsNftVault: Failed to receive the amount"
        );
        //Add Collats to each NFT
        for (uint256 i = 0; i < amounts.length; i++) {
            address nftAddress = nftAddresses[i];
            uint256 tokenId = tokenIds[i];
            uint256 amount = amounts[i];
            _addCollats(nftAddress, tokenId, amount);
        }
    }

    function _addCollats(
        address nftAddress,
        uint256 tokenId,
        uint256 amount
    ) private {
        collatsInVault += amount;
        _balances[nftAddress][tokenId] += amount;
        emit CollatsAdded(
            _msgSender(),
            nftAddress,
            tokenId,
            amount,
            _balances[nftAddress][tokenId]
        );
    }

    function poolAmounts(uint256[] memory amounts)
        private
        pure
        returns (uint256)
    {
        uint256 amount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            amount += amounts[i];
        }
        return amount;
    }

    function withdrawCollats(
        address to,
        address nftAddress,
        uint256 tokenId,
        uint256 amount
    ) public returns (bool) {
        //Check for ownership
        require(
            _msgSender() == IERC721Upgradeable(nftAddress).ownerOf(tokenId),
            "CollatsNftVault: Only the owner of the NFT can withdraw Collats"
        );

        //check for balance
        require(
            balanceOf(nftAddress, tokenId) >= amount,
            "CollatsNftVault: You don't have enough balance"
        );

        collatsInVault -= amount;

        //Decrease the amount
        _balances[nftAddress][tokenId] -= amount;

        //Send the Collats to the receiver
        require(
            collats.transfer(to, amount),
            "CollatsNftVault: Transfer failed"
        );

        //Emit Event
        emit CollatsWithdraw(
            to,
            nftAddress,
            tokenId,
            amount,
            _balances[nftAddress][tokenId]
        );
        return true;
    }

    function balanceOf(address nftAddress, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _balances[nftAddress][tokenId];
    }

    function getVersion() public pure returns (uint256) {
        return 0;
    }
}