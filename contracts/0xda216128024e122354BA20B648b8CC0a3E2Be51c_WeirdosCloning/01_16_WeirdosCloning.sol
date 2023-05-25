// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "erc721a/contracts/ERC721A.sol";

contract WeirdosCloning is ERC721A, Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 9272;
    uint256 public constant MINT_PRICE_ETH = 0.09272 ether;
    uint256 public mintPriceApe = 23;

    string public baseURI =
        "ipfs://QmS5eDVK2onoUXP6eoTmGVwd5ioUhxFRSsoB1gGF92euEW/";
    string public contractURI =
        "ipfs://QmYY8yQ1zpVDc1XoTmC7gpoRZbjai11U29uFpi5XG3MXi8";
    address public bankAddress = 0x19F52b6DB9CB5888e095ec5e188ea03cDCB5e173;
    IERC20 public apeTokenAddress;
    bool public claimActive = false;
    bool public creamlistActive = false;
    bool public communityActive = false;
    bool public publicActive = false;
    bytes32 public claimMerkleRoot;
    bytes32 public creamlistMerkleRoot;
    bytes32 public communityMerkleRoot;
    bytes32 public publicMerkleRoot;

    mapping(address => uint256) public claimAddressToMinted;
    mapping(address => uint256) public creamAddressToMinted;
    mapping(address => uint256) public communityAddressToMinted;

    constructor(IERC20 _apeTokenAddress)
        ERC721A("The Weirdos: Battle Royale", "WEIRDO")
    {
        apeTokenAddress = _apeTokenAddress;
    }

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "Caller is contract");
        _;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setcontractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function getContractURI() public view returns (string memory) {
        return contractURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function setBankAddress(address _bankAddress) external onlyOwner {
        bankAddress = _bankAddress;
    }

    function setTokenApePrice(uint256 _mintPriceApe) external onlyOwner {
        mintPriceApe = _mintPriceApe;
    }

    function setFreeClaimlistMerkleRoot(
        bool _claimActive,
        bytes32 _claimMerkleRoot
    ) external onlyOwner {
        claimActive = _claimActive;
        claimMerkleRoot = _claimMerkleRoot;
    }

    function setCreamlistMerkleRoot(
        bool _creamlistSaleActive,
        bytes32 _creamlistMerkleRoot
    ) external onlyOwner {
        creamlistActive = _creamlistSaleActive;
        creamlistMerkleRoot = _creamlistMerkleRoot;
    }

    function setCommunityMerkleRoot(
        bool _communitySaleActive,
        bytes32 _communityMerkleRoot
    ) external onlyOwner {
        delete claimMerkleRoot;
        delete creamlistMerkleRoot;
        communityActive = _communitySaleActive;
        communityMerkleRoot = _communityMerkleRoot;
    }

    function setPublicSalelistMerkleRoot(
        bool _publicSaleActive,
        bytes32 _publicMerkleRoot
    ) external onlyOwner {
        delete claimMerkleRoot;
        delete creamlistMerkleRoot;
        delete communityMerkleRoot;
        publicActive = _publicSaleActive;
        publicMerkleRoot = _publicMerkleRoot;
    }

    function _leaf(string memory allowance, string memory payload)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(payload, allowance));
    }

    function _verify(
        bytes32 leaf,
        bytes32[] memory proof,
        bytes32 rootOf
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, rootOf, leaf);
    }

    function claimMint(
        uint256 count,
        uint256 allowance,
        bytes32[] calldata proof
    ) public callerIsUser {
        require(claimActive, "Claim is not active");
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(
            _verify(
                _leaf(Strings.toString(allowance), payload),
                proof,
                claimMerkleRoot
            ),
            "Invalid proof supplied"
        );
        require(
            claimAddressToMinted[_msgSender()] + count < allowance + 1,
            "Exceeds claim allocation"
        );

        claimAddressToMinted[_msgSender()] += count;
        _safeMint(_msgSender(), count);
    }

    function creamMintETH(
        uint256 count,
        uint256 allowance,
        bytes32[] calldata proof
    ) public payable callerIsUser {
        require(creamlistActive, "Creamlist is not active");
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(
            _verify(
                _leaf(Strings.toString(allowance), payload),
                proof,
                creamlistMerkleRoot
            ),
            "Invalid proof supplied"
        );
        require(
            creamAddressToMinted[_msgSender()] + count < allowance + 1,
            "Exceeds Creamlist allocation"
        );
        require(count * MINT_PRICE_ETH == msg.value, "Invalid funds provided");

        creamAddressToMinted[_msgSender()] += count;
        _safeMint(_msgSender(), count);
    }

    function creamMintAPE(
        uint256 count,
        uint256 allowance,
        bytes32[] calldata proof
    ) public callerIsUser {
        require(creamlistActive, "Creamlist is not active");
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(
            _verify(
                _leaf(Strings.toString(allowance), payload),
                proof,
                creamlistMerkleRoot
            ),
            "Invalid proof supplied"
        );
        require(
            creamAddressToMinted[_msgSender()] + count < allowance + 1,
            "Exceeds Creamlist allocation"
        );

        uint256 apeCost = count * mintPriceApe;
        require(
            apeTokenAddress.balanceOf(msg.sender) >= apeCost,
            "NOT_ENOUGH_$APE"
        );

        apeTokenAddress.transferFrom(msg.sender, address(this), apeCost);
        creamAddressToMinted[_msgSender()] += count;
        _safeMint(_msgSender(), count);
    }

    function communityMintETH(
        uint256 count,
        uint256 allowance,
        bytes32[] calldata proof
    ) public payable callerIsUser {
        require(communityActive, "Communuity Mint is not active");
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(
            _verify(
                _leaf(Strings.toString(allowance), payload),
                proof,
                communityMerkleRoot
            ),
            "Invalid proof supplied"
        );
        require(
            communityAddressToMinted[_msgSender()] + count < allowance + 1,
            "Exceeds Community Mint allocation"
        );
        require(count * MINT_PRICE_ETH == msg.value, "Invalid funds provided");

        communityAddressToMinted[_msgSender()] += count;
        _safeMint(_msgSender(), count);
    }

    function communityMintAPE(
        uint256 count,
        uint256 allowance,
        bytes32[] calldata proof
    ) public callerIsUser {
        require(communityActive, "Community Mint is not active");
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(
            _verify(
                _leaf(Strings.toString(allowance), payload),
                proof,
                communityMerkleRoot
            ),
            "Invalid proof supplied"
        );
        require(
            communityAddressToMinted[_msgSender()] + count < allowance + 1,
            "Exceeds Community allocation"
        );

        uint256 apeCost = count * mintPriceApe;
        require(
            apeTokenAddress.balanceOf(msg.sender) >= apeCost,
            "NOT_ENOUGH_$APE"
        );

        apeTokenAddress.transferFrom(msg.sender, address(this), apeCost);
        communityAddressToMinted[_msgSender()] += count;
        _safeMint(_msgSender(), count);
    }

    function publicMintEth(
        uint256 count,
        bytes32[] calldata proof,
        string calldata antiBotPhrase,
        uint256 antiBotPhraseAllowance
    ) public payable callerIsUser {
        require(publicActive, "Public is not active");
        string memory payload = string(abi.encodePacked(antiBotPhrase));
        require(
            _verify(
                _leaf(Strings.toString(antiBotPhraseAllowance), payload),
                proof,
                publicMerkleRoot
            ),
            "Invalid proof supplied"
        );
        uint256 totalSupply = totalSupply();
        require(
            totalSupply + count < MAX_SUPPLY + 1,
            "Exceeds public mint supply"
        );
        require(count * MINT_PRICE_ETH == msg.value, "Invalid funds provided");
        _safeMint(_msgSender(), count);
    }

    function publicMintApe(
        uint256 count,
        bytes32[] calldata proof,
        string calldata antiBotPhrase,
        uint256 antiBotPhraseAllowance
    ) public callerIsUser {
        require(publicActive, "Public is not active");
        string memory payload = string(abi.encodePacked(antiBotPhrase));
        require(
            _verify(
                _leaf(Strings.toString(antiBotPhraseAllowance), payload),
                proof,
                publicMerkleRoot
            ),
            "Invalid proof supplied"
        );
        uint256 totalSupply = totalSupply();
        require(
            totalSupply + count < MAX_SUPPLY + 1,
            "Exceeds public mint supply"
        );
        uint256 apeCost = count * mintPriceApe;
        require(
            apeTokenAddress.balanceOf(msg.sender) >= apeCost,
            "NOT_ENOUGH_$APE"
        );

        apeTokenAddress.transferFrom(msg.sender, address(this), apeCost);
        _safeMint(_msgSender(), count);
    }

    function withdraw() external onlyOwner nonReentrant {
        require(bankAddress != address(0), "ZERO BANK ADDRESS");
        (bool success, ) = bankAddress.call{value: address(this).balance}("");
        require(success, "Failed to pay the bills");
    }

    function withdrawAPE() external onlyOwner nonReentrant {
        require(bankAddress != address(0), "ZERO BANK ADDRESS");
        uint256 balanceApe = apeTokenAddress.balanceOf(address(this));
        require(balanceApe > 0, "Not enough $APE");
        apeTokenAddress.transfer(bankAddress, balanceApe);
    }
}