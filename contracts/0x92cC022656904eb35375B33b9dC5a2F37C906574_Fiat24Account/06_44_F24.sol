// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Fiat24Account.sol";

contract F24 is ERC20, ERC20Permit, ERC20Votes, ERC20Pausable, ERC20Burnable, AccessControl {
    using SafeMath for uint256;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    uint256 public maxSupply;
    uint256 public airdropEndTime; // Timestamp
    uint256 public airdropClaim;

    mapping(uint256 => uint256) public claim;
    Fiat24Account fiat24account;

    constructor(address fiat24accountProxyAddress,
                uint256 maxSupply_,
                uint256 airdropTotal_,
                uint256 airdropEndTime_,
                uint256 airdropClaim_) ERC20("Fiat24", "F24") ERC20Permit("Fiat24") {
        require(airdropTotal_ <= maxSupply_, "F24: Airdrop higher than max supply - free supply");
        maxSupply = maxSupply_;
        _mint(msg.sender, maxSupply_ - airdropTotal_);
        _mint(address(this), airdropTotal_);

        airdropEndTime = airdropEndTime_;
        airdropClaim = airdropClaim_;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);

        fiat24account = Fiat24Account(fiat24accountProxyAddress);
    }

    function claimToken(uint256 tokenId) external {
        require(block.timestamp <= airdropEndTime, "F24: Airdrop expired");
        require(fiat24account.ownerOf(tokenId) == msg.sender ||
                fiat24account.historicOwnership(msg.sender) == tokenId, "F24: Not owner of token");
        require(fiat24account.status(tokenId) == Fiat24Account.Status.Live ||
                fiat24account.status(tokenId) == Fiat24Account.Status.Tourist,"F24: Not Live or Tourist");

        uint256 amount = eligibleClaimAmount(tokenId);
        if(amount > 0) {
            claim[tokenId] += amount;
            _transfer(address(this), msg.sender, amount);
        }
    }

    function eligibleClaimAmount(uint256 tokenId) public view returns(uint256) {
        require(block.timestamp <= airdropEndTime, "F24: Airdrop expired");
        uint256 amount = 0;
        bool success = true;
        if(fiat24account.exists(tokenId)) {
            if(fiat24account.status(tokenId) == Fiat24Account.Status.Live ||
               fiat24account.status(tokenId) == Fiat24Account.Status.Tourist ) {
                (success, amount) = airdropClaim.trySub(claim[tokenId]);
            }
        } else {
            success = false;
        }
        return success ? amount : 0;
    }

    function sweep(address dest) external {
        require(hasRole(OPERATOR_ROLE, msg.sender), "F24: Not an operator");
        require(block.timestamp > airdropEndTime, "F24: Claim period not yet ended");
        _transfer(address(this), dest, balanceOf(address(this)));
    }

    function decimals() public view virtual override returns (uint8) {
        return 2;
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Votes) {
        super._mint(account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
       super._beforeTokenTransfer(from, to, amount);

    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }
}