// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Collection1155Impl is Initializable, ContextUpgradeable, AccessControlEnumerableUpgradeable, ERC1155PausableUpgradeable, OwnableUpgradeable {
    bytes32 internal PROJECT_ADMIN;
    //tokenId -> phase
    mapping(uint256 => DROPPHASE) internal activePhases;
    //tokenId -> token
    mapping(uint256 => TOKEN) internal tokens;
    address payable royaltyAddress;
    uint256 internal royPercentage;
    string internal metaURI;
    string public name;

    struct TOKEN {
        uint256 id;
        uint256 maxSupply;
        uint256 maxPerMint;
        uint256 reserveQty;
        uint256 maxPerAddress;
        uint256 totalMinted;
        string uri;
    }

    struct DROPPHASE {
        uint256 tokenId;
        uint256 price;
        uint256 qtyAvailable;
        uint256 totalMinted;
        bytes32 restrictedMerkleRoot;
    }

    function initialize(
        string memory _name,
        string memory _uri,
        uint256 _royPercentage, 
        address payable _royaltyAddress, 
        address owner,
        address _adminAddress) public initializer {
        __ERC1155_init("");
        __Ownable_init();
        __AccessControl_init();
        __Pausable_init();

        transferOwnership(owner);
        PROJECT_ADMIN = keccak256("PROJECT_ADMIN");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(PROJECT_ADMIN, _adminAddress);
        grantRole(PROJECT_ADMIN, owner);

        require(_royaltyAddress != address(0x0), "");
        royaltyAddress = _royaltyAddress;
        royPercentage = _royPercentage;
        name = _name;
        metaURI = _uri;
    }

    function mintNFT(uint256 _count, uint256 _tokenId, bytes32[] memory proof) public whenNotPaused payable {
        DROPPHASE storage phase = getPhase(_tokenId);
        TOKEN storage _token = getToken(_tokenId);
        require((_token.id > 0) && (phase.tokenId > 0), '17');
        uint256 bal = balanceOf(msg.sender, _tokenId);

        bytes memory err = '';
        if ((_token.totalMinted + _count) > _token.maxSupply){
            err = '2';
        }
        else if ((phase.totalMinted + _count) > phase.qtyAvailable){
            err = '6';
        }
        else if ((bal + _count) > _token.maxPerAddress || (_count > _token.maxPerMint)){
            err = '4';
        }
        else if (msg.value < (phase.price * _count)){
            err = '7';
        }
        require(err.length == 0, string(err));

        //Permissions Checks
        if (phase.restrictedMerkleRoot > 0) {
            require(verify(phase.restrictedMerkleRoot, keccak256(abi.encodePacked(msg.sender)), proof), "8");
        }

        myMint(msg.sender, _tokenId, _count, _token.uri);
        royaltyAddress.transfer((_count * phase.price * royPercentage) / 100);
    }

    function myMint(address _to, uint256 _tokenId, uint256 _count, string memory _data) internal {
        DROPPHASE storage phase = getPhase(_tokenId);
        TOKEN storage _token = getToken(_tokenId);
        require((_token.id > 0) && (phase.tokenId > 0), "17");

        _mint(_to, _tokenId, _count, bytes(_data));

        phase.totalMinted += _count;
        _token.totalMinted += _count;
    }

    function withdraw() public payable onlyOwner whenNotPaused {
        uint256 balance = address(this).balance;
        require(balance > 0, "12");
        payable(msg.sender).transfer(balance);
    }

    function pause(bool doPause) public {
        require(hasRole(PROJECT_ADMIN, msg.sender), "E");
        doPause ? _pause() : _unpause();
    }

    function addToken(uint256 id,
        uint256 maxSupply,
        uint256 maxPerMint,
        uint256 reserveQty,
        uint256 maxPerAddress,
        string memory aUri) public whenNotPaused {
        require(hasRole(PROJECT_ADMIN, msg.sender), "E");

        tokens[id] = TOKEN(
            id,
            maxSupply,
            maxPerMint,
            reserveQty,
            maxPerAddress,
            0,
            aUri
        );
    }

    function activatePhase(uint256 _tokenId, uint256 price, uint256 qtyAvailable, uint256 totalMinted,
        bytes32 restrictedMerkleRoot
    ) public whenNotPaused {
        require(hasRole(PROJECT_ADMIN, msg.sender), "E");

        activePhases[_tokenId] = DROPPHASE(
            _tokenId,
            price,
            qtyAvailable,
            totalMinted,
            restrictedMerkleRoot
        );
    }

    function deactivatePhase(uint256 _tokenId) public whenNotPaused {
        require(hasRole(PROJECT_ADMIN, msg.sender), "E");
        delete activePhases[_tokenId];
    }

    function getPhase(uint256 _tokenId) private view returns (DROPPHASE storage) {
        return activePhases[_tokenId];
    }

    function getToken(uint256 _tokenId) private view returns (TOKEN storage) {
        return tokens[_tokenId];
    }

    function uri(uint256 _tokenId) override public view virtual returns (string memory) {
        return tokens[_tokenId].uri;
    }

    function contractURI() public view returns (string memory) {
        return metaURI;
    }

    function verify(
        bytes32 root,
        bytes32 leaf,
        bytes32[] memory proof
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        uint256 len = proof.length;
        for (uint256 i = 0; i < len; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash == root;
    }

    function airDrop(uint256 _tokenId, address[] memory accounts, string memory mURI) public whenNotPaused {
        require(hasRole(PROJECT_ADMIN, msg.sender), "E");
        for (uint i = 0; i < accounts.length; i++) {
            myMint(accounts[i], _tokenId, 1, mURI);
        }
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControlEnumerableUpgradeable, ERC1155Upgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}