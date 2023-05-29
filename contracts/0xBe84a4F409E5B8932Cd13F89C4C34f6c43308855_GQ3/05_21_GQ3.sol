// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721} from "openzeppelin-contracts/token/ERC721/ERC721.sol";
import {RevokableDefaultOperatorFilterer} from "./Base/RevokableDefaultOperatorFilterer.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/utils/ReentrancyGuard.sol";
import {MerkleProof} from "openzeppelin-contracts/cryptography/MerkleProof.sol";
import {AccessControl} from "openzeppelin-contracts/access/AccessControl.sol";

//         GGGGGGGGGGGGG     QQQQQQQQQ      333333333333333
//      GGG::::::::::::G   QQ:::::::::QQ   3:::::::::::::::33
//    GG:::::::::::::::G QQ:::::::::::::QQ 3::::::33333::::::3
//   G:::::GGGGGGGG::::GQ:::::::QQQ:::::::Q3333333     3:::::3
//  G:::::G       GGGGGGQ::::::O   Q::::::Q            3:::::3
// G:::::G              Q:::::O     Q:::::Q            3:::::3
// G:::::G              Q:::::O     Q:::::Q    33333333:::::3
// G:::::G    GGGGGGGGGGQ:::::O     Q:::::Q    3:::::::::::3
// G:::::G    G::::::::GQ:::::O     Q:::::Q    33333333:::::3
// G:::::G    GGGGG::::GQ:::::O     Q:::::Q            3:::::3
// G:::::G        G::::GQ:::::O  QQQQ:::::Q            3:::::3
//  G:::::G       G::::GQ::::::O Q::::::::Q            3:::::3
//   G:::::GGGGGGGG::::GQ:::::::QQ::::::::Q3333333     3:::::3
//    GG:::::::::::::::G QQ::::::::::::::Q 3::::::33333::::::3
//      GGG::::::GGG:::G   QQ:::::::::::Q  3:::::::::::::::33
//         GGGGGG   GGGG     QQQQQQQQ::::QQ 333333333333333
//                                   Q:::::Q
//                                    QQQQQQ

contract GQ3 is
    ERC721,
    RevokableDefaultOperatorFilterer,
    AccessControl,
    ReentrancyGuard
{
    uint256 public price;
    uint256 public maxSupply;
    uint256 public maxAmountPerTx;
    uint8 public phase;
    bool private revealed;
    string private contractURL;
    string private notRevealedUri;
    string private baseUri;
    bytes32 public merkleRoot;
    address private ownerAddress;
    uint256 private currentTokenId;
    mapping(address => uint256) private _minted;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(
        string memory _notRevealedUri,
        string memory _revealedUri
    ) ERC721("GQ3 Issue 001: Change is Good", "GQ3") {
        price = 0.1957 ether;
        currentTokenId = 1;
        maxSupply = 1661;
        maxAmountPerTx = 1;
        phase = 1; // 1, 2, or 3
        revealed = false;
        notRevealedUri = _notRevealedUri;
        baseUri = _revealedUri;
        ownerAddress = _msgSender();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, 0xEF0B56692F78A44CF4034b07F80204757c31Bcc9);
    }

    modifier onlyOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Caller is not a admin"
        );
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");
        _;
    }

    function owner() public view virtual override returns (address) {
        return ownerAddress;
    }

    function grantMinterRole(address _account) public onlyOwner {
        grantRole(MINTER_ROLE, _account);
    }

    function isOnAllowlist(
        bytes32[] memory _proof,
        address _claimer,
        uint256 _amount
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_claimer, _amount));
        return MerkleProof.verify(_proof, merkleRoot, leaf);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPhase(uint8 _newPhase) public onlyOwner {
        require(_newPhase < 4 && _newPhase > 0, "Invalid phase: 1, 2, 3");
        phase = _newPhase;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(
            _maxSupply > maxSupply,
            "New supply should be bigger than old one"
        );
        maxSupply = _maxSupply;
    }

    function setRevealed(bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function setNotRevealedURI(
        string memory _newNotRevealedURI
    ) public onlyOwner {
        notRevealedUri = _newNotRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseUri = _newBaseURI;
    }

    function setMaxAmountPerTx(uint256 _maxAmount) public onlyOwner {
        require(_maxAmount > 0, "Invalid param provided");
        maxAmountPerTx = _maxAmount;
    }

    function withdraw() public onlyOwner nonReentrant {
        uint256 _balance = address(this).balance;
        require(_balance > 0, "No amount to withdraw");

        (bool success, ) = _msgSender().call{value: _balance}("");
        require(success, "Transfer failed.");
    }

    function contractURI() public view returns (string memory) {
        return contractURL;
    }

    function setContractURI(string memory _contractURL) public onlyOwner {
        contractURL = _contractURL;
    }

    function mintedBalanceOf(address _address) public view returns (uint256) {
        return _minted[_address];
    }

    function airdrop(address _to, uint256 _amount) public onlyOwner {
        require(
            totalSupply() + _amount <= maxSupply,
            "Cannot mint that many tokens."
        );

        for (uint256 index = 0; index < _amount; index++) {
            _mint(_to, currentTokenId);
            currentTokenId += 1;
        }
        _minted[_to] += _amount;
    }

    function checkClaimEligibility(
        address _to,
        uint256 _ogHoldQuantity,
        uint256 _mintQuantity,
        bytes32[] memory _proof
    ) external view returns (string memory) {
        return
            _checkClaimEligibility(_to, _ogHoldQuantity, _mintQuantity, _proof);
    }

    function _checkClaimEligibility(
        address _to,
        uint256 _ogHoldQuantity,
        uint256 _mintQuantity,
        bytes32[] memory _proof
    ) internal view returns (string memory) {
        if (phase < 3) {
            if (!isOnAllowlist(_proof, _to, _ogHoldQuantity)) {
                return "Wallet address is not Allowlisted";
            }
        }
        if (phase > 1 && _mintQuantity > maxAmountPerTx) {
            return "Cannot mint that many tokens per tx";
        }
        if (phase == 1) {
            if (_minted[_to] + _mintQuantity > _ogHoldQuantity) {
                return "Cannot mint that many tokens per wallet";
            }
        } else if (phase == 2) {
            if (
                _minted[_to] + _mintQuantity >
                (_ogHoldQuantity + maxAmountPerTx)
            ) {
                return "Cannot mint that many tokens per wallet";
            }
        }
        if (totalSupply() + _mintQuantity > maxSupply) {
            return "NFT is sold out";
        }

        return "";
    }

    function claimTo(
        address _to,
        uint256 _ogHoldQuantity, // When phase 2, 3, ignore it as 0 for non og holders
        uint256 _mintQuantity,
        bytes32[] memory _proof
    ) external payable onlyMinter {
        string memory eligibility = _checkClaimEligibility(
            _to,
            _ogHoldQuantity,
            _mintQuantity,
            _proof
        );
        require(bytes(eligibility).length == 0, eligibility);

        require(
            msg.value >= _mintQuantity * price,
            "Not enough to pay for that"
        );

        for (uint256 index = 0; index < _mintQuantity; index++) {
            _safeMint(_msgSender(), currentTokenId);
            currentTokenId += 1;
        }
        _minted[_to] += _mintQuantity;
    }

    function webMint(
        uint256 _ogHoldQuantity, // When phase 2, 3, ignore it as 0 for non og holders
        uint256 _mintQuantity,
        bytes32[] memory _proof
    ) external payable {
        string memory eligibility = _checkClaimEligibility(
            _msgSender(),
            _ogHoldQuantity,
            _mintQuantity,
            _proof
        );
        require(bytes(eligibility).length == 0, eligibility);

        require(
            msg.value >= _mintQuantity * price,
            "Not enough to pay for that"
        );

        for (uint256 index = 0; index < _mintQuantity; index++) {
            _mint(_msgSender(), currentTokenId);
            currentTokenId += 1;
        }
        _minted[_msgSender()] += _mintQuantity;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist");
        if (!revealed) {
            return notRevealedUri;
        }
        return
            string(
                abi.encodePacked(baseUri, Strings.toString(_tokenId), ".json")
            );
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}