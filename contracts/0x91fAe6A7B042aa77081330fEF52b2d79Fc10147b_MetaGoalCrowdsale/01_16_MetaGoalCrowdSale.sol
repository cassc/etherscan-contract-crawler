// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Signer.sol";
import "erc721a/contracts/IERC721A.sol";
interface X721 is IERC721A{
    function mint(address , uint256 ) external;
    function current() external view returns (uint256);
}

contract MetaGoalCrowdsale is Signer, AccessControl {
    using SafeMath for uint256;
    bytes32 public constant GIFT_ROLE = keccak256("GIFT_ROLE");
    X721 public token;
    bool public opening; // crowdsale opening status

    event FreeMintingStarted(bool opening);

    constructor() Signer("METAGOAL") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GIFT_ROLE, msg.sender);
    }

    function mint(bytes calldata signature,uint256 cardId)
    external
    requiresSignature(signature,cardId)
    {
        require(opening, "Free mining has not yet begun");
        token.mint(msg.sender, 1);
    }

    function setNft(address _nft) external onlyRole(GIFT_ROLE) {
        require(_nft != address(0), "Invalid address");
        token = X721(_nft);
    }

    function setOpening(bool _opening) external onlyRole(GIFT_ROLE) {
        opening = _opening;
        emit FreeMintingStarted(opening);
    }

    function current() external view returns (uint256) {
        return token.current();
    }

    function gift(address[] calldata _accounts, uint256[] calldata _quantity)
    external
    onlyRole(GIFT_ROLE)
    {
        require(!opening, "The airdrop is over");
        require(
            _accounts.length == _quantity.length,
            "The two arrays are not equal in length"
        );
        for (uint256 index = 0; index < _accounts.length; index++) {
            token.mint(_accounts[index], _quantity[index]);
        }
    }

    function transferRoleAdmin(address newDefaultAdmin)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(newDefaultAdmin != address(0), "Invalid address");
        _setupRole(DEFAULT_ADMIN_ROLE, newDefaultAdmin);
    }
}