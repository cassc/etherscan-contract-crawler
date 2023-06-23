// SPDX-License-Identifier: MIT
// Archetype ParallelAutoAuctionExtension
//
//        d8888                 888               888
//       d88888                 888               888
//      d88P888                 888               888
//     d88P 888 888d888 .d8888b 88888b.   .d88b.  888888 888  888 88888b.   .d88b.
//    d88P  888 888P"  d88P"    888 "88b d8P  Y8b 888    888  888 888 "88b d8P  Y8b
//   d88P   888 888    888      888  888 88888888 888    888  888 888  888 88888888
//  d8888888888 888    Y88b.    888  888 Y8b.     Y88b.  Y88b 888 888 d88P Y8b.
// d88P     888 888     "Y8888P 888  888  "Y8888   "Y888  "Y88888 88888P"   "Y8888
//                                                            888 888
//                                                       Y8b d88P 888
//                                                        "Y88P"  888

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/ISharesHolder.sol";
import "./ParallelAutoAuction.sol";


error NotVip();

struct Options {
    bool sharesUpdaterUpdatingLocked;
    bool vipRequiredTokensLocked;
    bool vipIdsLocked;
}


contract FigmataAuction is ParallelAutoAuction, ISharesHolder {

    mapping(address => uint256) private _rewardTokenShares;
	mapping(address => bool) private _allowSharesUpdate;
    mapping(uint24 => bool) private _tokenIdIsVip;

    address[] public tokensRequiredToOwnToBeVip;

    Options public options;

    function createBid(uint24 nftId) override public payable {

        if (_tokenIdIsVip[nftId] && !userIsVip(msg.sender))
            revert NotVip();

		super.createBid(nftId);
		_rewardTokenShares[msg.sender] += msg.value;
	}

    /* ----------------------- *\
    |* Vip token configuration *|
    \* ----------------------- */
    function setVipIds(uint24[] memory ids, bool areVip) external onlyOwner {
        if (options.vipIdsLocked) revert OptionLocked();
        for (uint256 i = 0; i < ids.length; i++) _tokenIdIsVip[ids[i]] = areVip;
    }

    function isVipId(uint24 id) external view returns (bool) {
        return _tokenIdIsVip[id];
    }

    function setTokensRequiredToHoldToBeVip(address[] memory tokens) external onlyOwner {
        if (options.vipRequiredTokensLocked) revert OptionLocked(); 
        tokensRequiredToOwnToBeVip = tokens;
    }

    /**
     * @return itIs Only if `user` holds at least one `tokensRequiredToOwnToBeVip`.
     */
    function userIsVip(address user) public view returns (bool itIs) {
        for (uint256 i = 0; i < tokensRequiredToOwnToBeVip.length; i++)
            if (IERC721(tokensRequiredToOwnToBeVip[i]).balanceOf(user) > 0)
                return true;
    }


    /* ---------------------------- *\
    |* ISharesHolder implementation *|
    \* ---------------------------- */
	function getAndClearSharesFor(address user) external returns (uint256 shares) {
		require(_allowSharesUpdate[msg.sender]);
		shares = _rewardTokenShares[user];
		delete _rewardTokenShares[user];
	}

	function addSharesUpdater(address updater) external onlyOwner {
        if (options.sharesUpdaterUpdatingLocked) revert OptionLocked();
		_allowSharesUpdate[updater] = true;
	}

	function removeSharesUpdater(address updater) external onlyOwner {
        if (options.sharesUpdaterUpdatingLocked) revert OptionLocked();
		_allowSharesUpdate[updater] = false;
	}

	function getIsSharesUpdater(address updater) external view returns (bool) {
		return _allowSharesUpdate[updater];
	}

	function getTokenShares(address user) external view returns (uint256) {
		return _rewardTokenShares[user];
	}

    /* ---------------------------------- *\
    |* Contract locking and configuration *|
    \* ---------------------------------- */
    function lockSharesUpdaterUpdatingForever() external onlyOwner {
        options.sharesUpdaterUpdatingLocked = true;
    }
    
    function lockTokensRequiredToHoldToBeVipForever() external onlyOwner {
        options.vipRequiredTokensLocked = true;
    }

    function lockVipIdsForever() external onlyOwner {
        options.vipIdsLocked = true;
    }

}