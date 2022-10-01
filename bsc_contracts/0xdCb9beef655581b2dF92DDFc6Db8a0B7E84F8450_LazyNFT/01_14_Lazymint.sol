// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./ILazymint.sol";

/// @title Lazymint Contract
/// @notice This contract allows the mint of nft when the user decides and the creator doesn't need to pay the gas for the minting
/// @author Mariano Salazar
contract LazyNFT is AccessControl, ERC721URIStorage {
    error callerisnotaminter();
    error maxsupplyexceeded();
    error cannotbezero();
    error zeroaddress();
    error ispaused();

    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 internal maxsupply; //Enter here the max supply that you want the NFT collection to have.
    uint256 internal supply;

    //Here you place the wallet to which the administrator role would be given,
    //this for future changes in the roles of the contract.
    address public admin = 0x9B6029a309bC0A1B6ab9ACf962AfD90A8270900e;

    bool public paused = false;

    constructor(
        address _market,
        uint256 _maxsupply,
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {
        //This function (_setupRole) helps to assign an administrator role that can then assign new roles.
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x30268390218B20226FC101cD5651A51b12C07470);
        _setupRole(MINTER_ROLE, _market);
        maxsupply = _maxsupply;
    }

    function totalSupply() public view returns (uint256) {
        return supply;
    }

    function maxSupply() public view returns (uint256) {
        return maxsupply;
    }

    function redeem(
        address _redeem,
        uint256 _tokenid,
        string memory _uri
    ) external returns (uint256) {
        if (!hasRole(MINTER_ROLE, msg.sender)) {
            revert callerisnotaminter();
        }
        if (paused) {
            revert ispaused();
        }
        if (_tokenid == 0) {
            revert cannotbezero();
        }
        if (_tokenid > maxsupply) {
            revert maxsupplyexceeded();
        }
        if (_redeem == address(0)) {
            revert zeroaddress();
        }
        ++supply;
        _safeMint(_redeem, _tokenid);
        _setTokenURI(_tokenid, _uri);
        return _tokenid;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxsupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    //If you need the option to pause the contract, activate this function and the ADMIN role.
    function setPaused(bool _state) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not Admin");
        paused = _state;
    }
}