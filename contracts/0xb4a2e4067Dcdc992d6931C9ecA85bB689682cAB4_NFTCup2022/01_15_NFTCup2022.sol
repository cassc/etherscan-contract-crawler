// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

pragma solidity ^0.8.9;

contract NFTCup2022 is ERC721Enumerable, Ownable, Pausable {
    using Strings for uint256;
    using SafeMath for uint256;

    // metadata base url
    string private _nftBaseURI;
    // giveaway limit to market campaign
    uint256 private constant NUMBER_RESERVED_GIVEAWAY = 100;
    // public key to validate match prediction file
    address public constant signerPubKey = 0x64C28c9f8854fde4672909C93260E333b37932b9;
    // base mint price
    uint256 public playerPrice = 0.05 ether;
    // controls how many tokens were given
    uint256 public giveawayTokensGiven;
    // map giveaway tokenId to address
    mapping(address => uint256[]) private addressToGiveawayTokensId;
    // map address to withdraw balance
    mapping(address => uint256) public pendingWithdrawals;
    // map matchNumber to signature
    mapping(uint256 => string) public matchesToSigHash;

    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    enum CouponType {
        Giveaway
    }

    event PlayerMinted(address from, uint256 tokenId, uint8 team);

    event BalanceWithdrawn(address from, uint256 value);

    event MatchPredictionSigAdded(uint256 matchNumber, string sigHash);

    // validate coupon cryptographically
    modifier validateCoupon(Coupon memory coupon, CouponType couponType) {
        bytes32 digest = keccak256(abi.encode(couponType, _msgSender()));
        require(_isVerifiedCoupon(digest, coupon), "Invalid coupon");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) ERC721(name, symbol) {
        _nftBaseURI = baseURI;
    }

    /**
     * @dev internal view to get the base url
     */
    function _baseURI() internal view override returns (string memory) {
        return (_nftBaseURI);
    }

    /**
     * @dev public view to get token metadata url
     * @param tokenId uint256
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev public function to mint a player
     * @param team uint8 official FIFA team codes (3 digits) alfabetically ordered from 1 to 32.
     */
    function mintPlayer(uint8 team) public payable whenNotPaused {
        require(playerPrice == msg.value, "Amount of Ether sent is not correct");

        _mintPlayer(team);
    }

    /**
     * @dev public function to claim a giveaway player
     * @param team uint8 FIFA team codes (3 digits) alfabetically ordered from 1 to 32.
     * @param coupon Coupon signed by us
     */
    function claimGiveaway(uint8 team, Coupon memory coupon) public validateCoupon(coupon, CouponType.Giveaway) {
        uint256[] storage giveawayTokens = addressToGiveawayTokensId[_msgSender()];

        require(giveawayTokens.length == 0, "Coupon already claimed");
        require(giveawayTokensGiven.add(1) <= NUMBER_RESERVED_GIVEAWAY, "Exceeds the reserved supply of giveaway");

        uint256 tokenId = _mintPlayer(team);
   
        giveawayTokens.push(tokenId);
        giveawayTokensGiven = giveawayTokensGiven.add(1);
    }

    /**
     * @dev public function to change base URI.
     * it will be committed to ipfs in the end of the competition
     * @param baseURI string base storage url
     */
    function changeBaseURI(string memory baseURI) public onlyOwner {
        _nftBaseURI = baseURI;
    }

    /**
     * @dev public view to get a list of players by owner
     * @param owner address
     */
    function tokensByOwner(address owner) public view returns (uint256[] memory) {
        uint256 numOfTokens = ERC721.balanceOf(owner);
        uint256[] memory tokenIndexes = new uint256[](numOfTokens);
        for (uint256 i = 0; i < numOfTokens; i++) {
            tokenIndexes[i] = ERC721Enumerable.tokenOfOwnerByIndex(owner, i);
        }

        return tokenIndexes;
    }

    /**
     * @dev public function to inform the winners and splitting the prize.
     * @param tokenIds ordered by ranking 1 to 10
     */
    function enterWinners(uint256[] memory tokenIds) public onlyOwner {
        // contract balance
        uint256 balance = address(this).balance;
        // 15% of it
        uint256 winnersBalance = balance.mul(15).div(100);

        // make the prize distribution for the winners
        for (uint8 n = 0; n < tokenIds.length; n++) {
            address account = ownerOf(tokenIds[n]);
            pendingWithdrawals[account] = winnersBalance.mul(_getPrizePercentage(n + 1)).div(100);
        }
    }

    /**
     * @dev private function to get the prize percentage
     * @param position uint8 rank position
     */
    function _getPrizePercentage(uint8 position) private pure returns (uint256) {
        if (position == 1) {
            return 35;
        }
        if (position == 2) {
            return 20;
        }
        if (position == 3) {
            return 10;
        }
        if (position == 4 || position == 5) {
            return 8;
        }
        if (position == 6 || position == 7) {
            return 6;
        }
        if (position == 8 || position == 9) {
            return 3;
        }
        return 1;
    }

    /**
     * @dev public view to return peding balance to withdraw
     * @param fromAddress account address
     */
    function getWithdrawBalance(address fromAddress) public view returns (uint256) {
        return pendingWithdrawals[fromAddress];
    }

    /**
     * @dev public function to claim players prize
     */
    function withdrawPrize() public payable {
        address sender = _msgSender();
        uint256 amount = pendingWithdrawals[sender];

        require(amount > 0, "you got no balance to withdraw");

        // clear balance to avoid re-entry
        pendingWithdrawals[sender] = 0;

        payable(sender).transfer(amount);

        emit BalanceWithdrawn(sender, amount);
    }

    /**
     * @dev public function to withdraw contract balance
     */
    function withdraw() public payable onlyOwner {
        address sender = _msgSender();
        uint256 balance = address(this).balance;
        payable(sender).transfer(balance);
    }

    /**
     * @dev public function to register the signed hash of all players prediction scores
     * @param matchNumber match number
     * @param sigHash signed hash
     */
    function addMatchPredictionsSig(uint256 matchNumber, string memory sigHash) public onlyOwner {
        matchesToSigHash[matchNumber] = sigHash;

        emit MatchPredictionSigAdded(matchNumber, sigHash);
    }

    /**
     * @dev public function to get the sig hash
     * @param matchNumber match number
     */
    function getMatchPredictionHash(uint256 matchNumber) public view returns (string memory) {
        return matchesToSigHash[matchNumber];
    }

    /// @dev See {mintPlayer}.
    function _mintPlayer(uint8 team) private returns (uint256) {
        require(team > 0 && team <= 32, "Team code must be between 1 and 32");

        address sender = _msgSender();
        uint256 tokenId = totalSupply();

        _safeMint(sender, tokenId);

        emit PlayerMinted(sender, tokenId, team);

        return tokenId;
    }

    /**
     * @dev private function to validate the coupon sig
     */
    function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon) internal pure returns (bool) {
        address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
        require(signer != address(0), "ECDSA: invalid signature");
        return signer == signerPubKey;
    }
}