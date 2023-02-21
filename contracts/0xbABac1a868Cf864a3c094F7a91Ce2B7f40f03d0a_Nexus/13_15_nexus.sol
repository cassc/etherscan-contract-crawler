// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract Nexus is ERC721A, ERC2981, AccessControl {
    using Strings for uint256;
    bytes32 public constant MGR_ROLE = keccak256("MGR_ROLE");

    bytes32 public merkleRootG;
    bytes32 public merkleRootP;
    bytes32 public merkleRootB;

    // mint records.
    mapping(address => uint256) internal _minted;

    // modifier for manager role.
    modifier onlyMgr() {
        require(hasRole(MGR_ROLE, _msgSender()), "Caller is not a manager");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyReceiver,
        uint96 _royaltyFraction
    ) ERC721A(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MGR_ROLE, _msgSender());
        _setDefaultRoyalty(_royaltyReceiver, _royaltyFraction);
    }

    function manualMintBlack(address _address) external onlyMgr {
        require(0 >= _minted[_address], "Address already minted.");
        _safeMint(_address, 3);
        _minted[_address] += 3;

        mapTokenKind[totalSupply() - 2] = 3;
        mapTokenKind[totalSupply() - 1] = 4;
        mapTokenKind[totalSupply()]     = 5;
    }

    function manualMintPlatinum(address _address) external onlyMgr {
        require(0 >= _minted[_address], "Address already minted.");
        _safeMint(_address, 2);
        _minted[_address] += 2;

        mapTokenKind[totalSupply() - 1] = 2;
        mapTokenKind[totalSupply()]     = 5;
    }

    function manualMintGold(address _address) external onlyMgr {
        require(0 >= _minted[_address], "Address already minted.");
        _safeMint(_address, 1);
        _minted[_address] += 1;

        mapTokenKind[totalSupply()] = 1;
    }

    function mintBlack(bytes32[] calldata _merkleProof) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRootB, leaf),"Invalid Merkle Proof");
        require(0 >= _minted[msg.sender], "You already minted.");
        _safeMint(msg.sender, 3);
        _minted[msg.sender] += 3;

        mapTokenKind[totalSupply() - 2] = 3;
        mapTokenKind[totalSupply() - 1] = 4;
        mapTokenKind[totalSupply()]     = 5;
    }

    function mintPlatinum(bytes32[] calldata _merkleProof) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRootP, leaf),"Invalid Merkle Proof");
        require(0 >= _minted[msg.sender], "You already minted.");
        _safeMint(msg.sender, 2);
        _minted[msg.sender] += 2;

        mapTokenKind[totalSupply() - 1] = 2;
        mapTokenKind[totalSupply()]     = 5;
    }

    function mintGold(bytes32[] calldata _merkleProof) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRootG, leaf),"Invalid Merkle Proof");
        require(0 >= _minted[msg.sender], "You already minted.");
        _safeMint(msg.sender, 1);
        _minted[msg.sender] += 1;

        mapTokenKind[totalSupply()]     = 1;
    }

    // Token Kind Setting
    string public _kindGTokenURI;
    string public _kindPTokenURI;
    string public _kindBTokenURI;
    string public _kindB1TokenURI;
    string public _kindB2TokenURI;

    //token kind Map
    mapping(uint256 => uint256) public mapTokenKind;

    //retuen BaseURI.internal.
    function _baseURI(uint256 tokenId) internal view returns (string memory) {
        if (mapTokenKind[tokenId] == 1) {
            return _kindGTokenURI;
        } else if (mapTokenKind[tokenId] == 2) {
            return _kindPTokenURI;
        } else if (mapTokenKind[tokenId] == 3) {
            return _kindBTokenURI;
        } else if (mapTokenKind[tokenId] == 4) {
            return _kindB1TokenURI;
        } else if (mapTokenKind[tokenId] == 5) {
            return _kindB2TokenURI;
        } else {
            return _kindBTokenURI;
        }
    }

    // return tokenURI
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        return _baseURI(_tokenId);
    }

    //set URI
    function setKindG_URI(string calldata baseURI) external onlyMgr {
        _kindGTokenURI = baseURI;
    }
    function setKindP_URI(string calldata baseURI) external onlyMgr {
        _kindPTokenURI = baseURI;
    }
    function setKindB_URI(string calldata baseURI) external onlyMgr {
        _kindBTokenURI = baseURI;
    }
    function setKindB1_URI(string calldata baseURI) external onlyMgr {
        _kindB1TokenURI = baseURI;
    }
    function setKindB2_URI(string calldata baseURI) external onlyMgr {
        _kindB2TokenURI = baseURI;
    }

    // set MerkleRoot
    function setMerkleRootG(bytes32 _merkleRoot) external onlyMgr {
        merkleRootG= _merkleRoot;
    }
    function setMerkleRootP(bytes32 _merkleRoot) external onlyMgr {
        merkleRootP= _merkleRoot;
    }
    function setMerkleRootB(bytes32 _merkleRoot) external onlyMgr {
        merkleRootB= _merkleRoot;
    }

    // reset mint record
    function resetMinted(address _address) external onlyMgr {
        _minted[_address] = 0;
    }

    //start from 1.adjust.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    //set Default Royalty._feeNumerator 500 = 5% Royalty
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator)
        external
        virtual
        onlyMgr
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }
    // for ERC2981
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    //for ERC2981 Opensea
    function contractURI() external view virtual returns (string memory) {
        return _formatContractURI();
    }
    //make contractURI
    function _formatContractURI() internal view returns (string memory) {
        (address receiver, uint256 royaltyFraction) = royaltyInfo(
            0,
            _feeDenominator()
        ); //tokenid=0
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"seller_fee_basis_points":',
                                Strings.toString(royaltyFraction),
                                ', "fee_recipient":"',
                                Strings.toHexString(
                                    uint256(uint160(receiver)),
                                    20
                                ),
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}