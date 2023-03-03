pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "../libs/helpers/Errors.sol";

contract Ordinals is Initializable, OwnableUpgradeable {

    address public _admin; // is a mutil sig address when deploy
    address public _parameterAddr;

    mapping(address => bool) public _caller;
    mapping(address => mapping(uint256 => string)) public _inscription;

    function initialize(address admin, address parameterControl) initializer virtual public {
        require(admin != Errors.ZERO_ADDR, Errors.INV_ADD);
        //        require(parameterControl != Errors.ZERO_ADDR, Errors.INV_ADD);

        _admin = admin;
        _parameterAddr = parameterControl;
        __Ownable_init();
    }

    function changeAdmin(address newAdm) external {
        require(msg.sender == _admin && newAdm != Errors.ZERO_ADDR, Errors.ONLY_ADMIN_ALLOWED);

        if (_admin != newAdm) {
            _admin = newAdm;
        }
    }

    function changeParam(address newAdm) external {
        require(msg.sender == _admin && newAdm != Errors.ZERO_ADDR, Errors.ONLY_ADMIN_ALLOWED);

        if (_parameterAddr != newAdm) {
            _parameterAddr = newAdm;
        }
    }

    function setCaller(address caller, bool approved) external {
        require(msg.sender == _admin, "INV_CALLER");
        _caller[caller] = approved;
    }

    function setInscription(address coll, uint256 tokenId, string memory inscriptionId) external {
        require(bytes(_inscription[coll][tokenId]).length == 0, "DOUBLE");
        IERC721Upgradeable tokenERC721 = IERC721Upgradeable(coll);
        require(tokenERC721.ownerOf(tokenId) == msg.sender || _caller[msg.sender] || msg.sender == _admin, "INV_CALLER");
        _inscription[coll][tokenId] = inscriptionId;
    }
}