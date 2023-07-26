// SPDX-License-Identifier: proprietary
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import './vendor/ISelfkeyIdAuthorization.sol';

contract SelfkeyIdSoulboundNFT is ERC721EnumerableUpgradeable, OwnableUpgradeable {

    event ControllerChanged(address indexed _address);
    event AuthorizationContractAddressChanged(address indexed _address);
    event BaseTokenUriChanged(string newUri);

    address public selfkeyAuthorizationContractAddress;
    address public controller;

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdTracker;

    string private _baseTokenURI;

    function initialize(string memory _name, string memory _symbol, string memory _tokenUri, address _selfkeyAuthorizationContractAddress) public initializer {
        __Ownable_init();
        __ERC721_init(_name, _symbol);
        _baseTokenURI = _tokenUri;
        selfkeyAuthorizationContractAddress = _selfkeyAuthorizationContractAddress;
    }

    modifier onlyController() {
        require(msg.sender == controller, "Restricted to controllers");
        _;
    }

    function isController(address _address) internal view returns (bool) {
        return (_address == controller);
    }

    function setController(address _newController) public onlyOwner {
        controller = _newController;
        emit ControllerChanged(_newController);
    }

    function setAuthorizationContractAddress(address _newAuthorizationContractAddress) public onlyOwner {
        selfkeyAuthorizationContractAddress = _newAuthorizationContractAddress;
        emit AuthorizationContractAddressChanged(_newAuthorizationContractAddress);
    }

    function setBaseURI(string calldata _newURI) public onlyOwner {
        _baseTokenURI = _newURI;
        emit BaseTokenUriChanged(_baseTokenURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override (ERC721Upgradeable, IERC721Upgradeable) {
        if (isController(msg.sender)) {
            _transfer(from, to, tokenId);
        }
        else {
            require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not token owner nor approved");
            _transfer(from, to, tokenId);
        }
    }

     function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override (ERC721Upgradeable, IERC721Upgradeable) {
        safeTransferFrom(from, to, tokenId, "");
    }


    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId) || isController(msg.sender), "Caller is not token owner nor approved");
        _burn(tokenId);
    }

    function mint(address to, bytes32 _param, uint _timestamp, address _signer, bytes memory signature) public virtual {
        // Verify payload
        if (selfkeyAuthorizationContractAddress != address(0)) {
            ISelfkeyIdAuthorization registry = ISelfkeyIdAuthorization(selfkeyAuthorizationContractAddress);
            registry.authorize(address(this), to, 1, 'mint', _param, _timestamp, _signer, signature);
        }

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    /**
     * When from and to are both non-zero, from 's tokenId will be transferred to to .
     * When from is zero, tokenId will be minted for to .
     * When to is zero, from 's tokenId will be burned.
     * from cannot be the zero address.
     * to cannot be the zero address.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        if (from == address(0)) {
            /*
            if (!hasRole(CONTROLLER_ROLE, _msgSender())) {
                require(registryContractAddress != address(0), "No credential record found");
                ISelfkeyIdRegistry registry = ISelfkeyIdRegistry(registryContractAddress);
                bytes32 credType = keccak256("SK_CRED_SELKFEYID");
                require(registry.isVerified(_msgSender(), credType), "No credential record found");
            }
            */
            require(balanceOf(to) == 0, "Address already has a Selfkey.ID NFT");
        }
        else {
            // Disallow burning
            if (to == address(0)) {
                require(isController(_msgSender()), "Selfkey.ID Soulbound NFT is not burnable");
            }

            // Disallow tranfers
            if (to != address(0)) {
                require(isController(_msgSender()), "Selfkey.ID Soulbound NFT is not transferable");
            }
        }

        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // do stuff before every transfer
        // e.g. check that vote (other than when minted)
        // being transferred to registered candidate
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}