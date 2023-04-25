// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWomanSeekersNewDawn.sol";

contract RoyaltyGetter is Ownable {
    IWomanSeekersNewDawn Collection;

    uint256 public TR1;
    uint256 public TR2;

    mapping(uint256 => uint256) public TokenIdsLastClaimedAtTR1;
    mapping(uint256 => uint256) public TokenIdsLastClaimedAtTR2;


    constructor(address _collection) {
        Collection = IWomanSeekersNewDawn(_collection);

    }

    function changeCollection(address _collection) public onlyOwner {
        Collection = IWomanSeekersNewDawn(_collection);

    }

  

    /**
     * Insert full of partial array of your tokenIds. Can be obtain by tokensOfOwner(). For full royalties array length must be
     equal to your balanceOf()
     */
    function getYourRoyaltyForGrantedArray(uint256[] memory _yourTokenIds) public {
        require(
            checkOwnershipOfTokens(msg.sender, _yourTokenIds),
            "you're not owner of these tokens at all"
        );

        uint256 amountToPayout;
        for (uint256 i = 0; i < Collection.balanceOf(msg.sender); i++) {
            if (_yourTokenIds[i] <= 1000) {
                amountToPayout +=
                    (TR1 - TokenIdsLastClaimedAtTR1[_yourTokenIds[i]]) /
                    (Collection.totalSupply());
                TokenIdsLastClaimedAtTR1[_yourTokenIds[i]] = TR1;
            }

            if (_yourTokenIds[i] > 1000 && _yourTokenIds[i] <= 4000) {
                amountToPayout +=
                    (6 * (TR2 - TokenIdsLastClaimedAtTR2[_yourTokenIds[i]])) /
                    (10 * Collection.totalSupply());
                TokenIdsLastClaimedAtTR2[_yourTokenIds[i]] = TR2;
            }

            if (_yourTokenIds[i] > 4000) {
                amountToPayout +=
                    (4 * (TR2 - TokenIdsLastClaimedAtTR2[_yourTokenIds[i]])) /
                    (10 * Collection.totalSupply());
                TokenIdsLastClaimedAtTR2[_yourTokenIds[i]] = TR2;
            }
        }

        (bool os, ) = payable(msg.sender).call{value: amountToPayout}("");
        require(os);
    }

    

    function checkOwnershipOfTokens(
        address _who,
        uint256[] memory _yourTokenIds
    ) public view returns (bool) {
        for (uint256 i = 0; i < Collection.balanceOf(_who); i++) {
            if (Collection.ownerOf(_yourTokenIds[i]) != _who) {
                return false;
            }
        }
        return true;
    }

    /**
     * Insert full of partial array of your tokenIds. Can be obtain by tokensOfOwner(). For full royalties array length must be
     equal to your balanceOf()
     */
    function calculateAvailableRoyaltiesForGrantedArray(
        uint256[] memory _yourTokenIds
    ) public view returns (uint256) {
        require(
            checkOwnershipOfTokens(msg.sender, _yourTokenIds),
            "you're not owner of these tokens at all"
        );

        uint256 amountToPayout;
        for (uint256 i = 0; i < Collection.balanceOf(msg.sender); i++) {
            if (_yourTokenIds[i] <= 1000) {
                amountToPayout +=
                    (TR1 - TokenIdsLastClaimedAtTR1[_yourTokenIds[i]]) /
                    (Collection.totalSupply());
            }

            if (_yourTokenIds[i] > 1000 && _yourTokenIds[i] <= 4000) {
                amountToPayout +=
                    (6 * (TR2 - TokenIdsLastClaimedAtTR2[_yourTokenIds[i]])) /
                    (10 * Collection.totalSupply());
            }

            if (_yourTokenIds[i] > 4000) {
                amountToPayout +=
                    (4 * (TR2 - TokenIdsLastClaimedAtTR2[_yourTokenIds[i]])) /
                    (10 * Collection.totalSupply());
            }
        }

        return amountToPayout;
    }

    receive() external payable {
        if (Collection.lastTokenIdTransfer() == 1) {
            TR1 += msg.value;
        }

        if (Collection.lastTokenIdTransfer() == 2) {
            TR2 += msg.value;
        }
    }

    //for emergency reasons
    function getBalance() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}