// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";

contract RoyaltySplitter is Initializable {
    address payable public twoFiveSix;
    uint96 public twoFiveSixShare;
    address payable public thirdParty;
    uint96 public thirdPartyShare;
    address payable public artist;

    /**
     * @notice Initializes the RoyaltySplitter contract with artist, twoFiveSix, and twoFiveSixShare values
     * @dev This function is called only once during contract creation
     * @param _artist The address of the artist who will receive a portion of the contract's balance
     * @param _twoFiveSix The address of the other party who will receive a portion of the contract's balance
     * @param _twoFiveSixShare The percentage of the contract's balance that will be sent to twoFiveSix
     */
    function initRoyaltySplitter(
        address payable _twoFiveSix,
        uint96 _twoFiveSixShare,
        address payable _thirdParty,
        uint96 _thirdPartyShare,
        address payable _artist
    ) public initializer {
        artist = _artist;
        twoFiveSix = _twoFiveSix;
        twoFiveSixShare = _twoFiveSixShare;
        if (_thirdParty != address(0)) {
            thirdParty = _thirdParty;
            thirdPartyShare = _thirdPartyShare;
        }
    }

    /**
     * @notice Allows the artist or twoFiveSix to withdraw their share from the contract's balance
     * @dev When either the artist or twoFiveSix calls this function, their respective share will be sent to both parties
     */
    function withdraw() public {
        require(
            (msg.sender == twoFiveSix ||
                msg.sender == artist ||
                msg.sender == thirdParty),
            "Not allowed"
        );
        uint256 balance = address(this).balance;

        if (thirdParty == address(0)) {
            uint256 twoFiveSixBalance = (balance * twoFiveSixShare) / 10000;
            uint256 artistBalance = (balance - twoFiveSixBalance);

            twoFiveSix.transfer(twoFiveSixBalance);
            artist.transfer(artistBalance);
        } else {
            uint256 twoFiveSixBalance = (balance * twoFiveSixShare) / 10000;
            uint256 thirdPartyBalance = (balance * thirdPartyShare) / 10000;
            uint256 artistBalance = (balance -
                twoFiveSixBalance -
                thirdPartyBalance);

            twoFiveSix.transfer(twoFiveSixBalance);
            thirdParty.transfer(thirdPartyBalance);
            artist.transfer(artistBalance);
        }
    }

    function withdrawToken(IERC20Upgradeable token) public {
        require(
            (msg.sender == twoFiveSix ||
                msg.sender == artist ||
                msg.sender == thirdParty),
            "Not allowed"
        );

        uint256 balance = token.balanceOf(address(this));

        if (thirdParty == address(0)) {
            uint256 twoFiveSixBalance = (balance * twoFiveSixShare) / 10000;
            uint256 artistBalance = (balance - twoFiveSixBalance);

            SafeERC20Upgradeable.safeTransfer(token, artist, artistBalance);
            SafeERC20Upgradeable.safeTransfer(
                token,
                twoFiveSix,
                twoFiveSixBalance
            );
        } else {
            uint256 twoFiveSixBalance = (balance * twoFiveSixShare) / 10000;
            uint256 thirdPartyBalance = (balance * thirdPartyShare) / 10000;
            uint256 artistBalance = (balance -
                twoFiveSixBalance -
                thirdPartyBalance);

            SafeERC20Upgradeable.safeTransfer(
                token,
                twoFiveSix,
                twoFiveSixBalance
            );
            SafeERC20Upgradeable.safeTransfer(
                token,
                thirdParty,
                thirdPartyBalance
            );
            SafeERC20Upgradeable.safeTransfer(token, artist, artistBalance);
        }
    }

    /**
     * @dev Fallback function to accept incoming ether transfers to the contract
     */
    receive() external payable {}
}