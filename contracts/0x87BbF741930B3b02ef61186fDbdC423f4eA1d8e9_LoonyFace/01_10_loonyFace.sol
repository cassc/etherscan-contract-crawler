// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract LoonyFace is ERC721A, DefaultOperatorFilterer, Ownable {
    using SafeMath for uint256;
    address public signer;
    string public baseUri;
    address public genesisAddress;
    uint256 public genesisClaimCount = 0;
    uint256 public mintCount = 0;
    uint256 public genesisClaimLimit = 100;
    uint256 public mintLimit = 1800;
    uint256 public maxCount = 1900;
    bool genesisClaimAvailable = false;
    bool mintAvailable = false;
    uint256 public genesisClaimPrice = 0;
    uint256 public whiteListMintPrice = 25000000000000000;
    uint256 public normalMintPrice = 35000000000000000;
    uint256 public individualGenesisClaimLimit = 1;
    uint256 public individualMintLimit = 3;
    mapping(uint256 => uint256) internal genesisClaimMap;
    mapping(address => uint256) internal mintMap;
    mapping(string => bool) internal nonceMap;
    mapping(uint256 => uint256) internal localStakeMap;
    bool localStakeAvailable = false;
    bool localRedeemAvailable = false;

    constructor() ERC721A("Loony Face", "LOONY FACE") {}

    event MintSuccess(address indexed operatorAddress, uint256 startId, uint256 quantity, uint256 price, string nonce, uint256 blockHeight);

    event LocalStakeSuccess(address indexed operatorAddress, uint256 tokenId, uint256 blockTimestamp);

    event LocalRedeemSuccess(address indexed operatorAddress, uint256 tokenId, uint256 blockTimestamp);

    //******Settings******
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseUri = _newURI;
    }

    function setMaxCount(uint256 _maxCount) public onlyOwner {
        maxCount = _maxCount;
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function setGenesisAddress(address _genesisAddress) public onlyOwner {
        genesisAddress = _genesisAddress;
    }

    function setGenesisClaimAvailable(bool _genesisClaimAvailable) public onlyOwner {
        genesisClaimAvailable = _genesisClaimAvailable;
    }

    function setMintAvailable(bool _mintAvailable) public onlyOwner {
        mintAvailable = _mintAvailable;
    }

    function setGenesisClaimPrice(uint256 _genesisClaimPrice) public onlyOwner {
        genesisClaimPrice = _genesisClaimPrice;
    }

    function setWhiteListMintPrice(uint256 _whiteListMintPrice) public onlyOwner {
        whiteListMintPrice = _whiteListMintPrice;
    }

    function setNormalMintPrice(uint256 _normalMintPrice) public onlyOwner {
        normalMintPrice = _normalMintPrice;
    }

    function setGenesisClaimLimit(uint256 _genesisClaimLimit) public onlyOwner {
        genesisClaimLimit = _genesisClaimLimit;
    }

    function setMintLimit(uint256 _mintLimit) public onlyOwner {
        mintLimit = _mintLimit;
    }

    function setIndividualGenesisClaimLimit(uint256 _individualGenesisClaimLimit) public onlyOwner {
        individualGenesisClaimLimit = _individualGenesisClaimLimit;
    }

    function setIndividualMintLimit(uint256 _individualMintLimit) public onlyOwner {
        individualMintLimit = _individualMintLimit;
    }

    function setLocalStakeAvailable(bool _localStakeAvailable) public onlyOwner {
        localStakeAvailable = _localStakeAvailable;
    }

    function setLocalRedeemAvailable(bool _localRedeemAvailable) public onlyOwner {
        localRedeemAvailable = _localRedeemAvailable;
    }

    function airdrop(address to, uint256 quantity) public onlyOwner {
        require(
            _nextTokenId() + quantity <= maxCount,
            "The quantity exceeds the stock!"
        );
        _safeMint(to, quantity);
    }

    function withdrawAll() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdraw(uint256 amount) public payable onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function adminLocalStake(uint256[] memory tokenIds) public onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (localStakeMap[tokenId] == 0) {
                localStakeMap[tokenId] = block.timestamp;
                emit LocalStakeSuccess(msg.sender, tokenId, block.timestamp);
            }
        }
    }

    function adminLocalRedeem(uint256[] memory tokenIds) public onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (localStakeMap[tokenId] > 0) {
                localStakeMap[tokenId] = 0;
                emit LocalRedeemSuccess(msg.sender, tokenId, block.timestamp);
            }
        }
    }

    function adminBurn(uint256[] memory tokenIds) public onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }
    }

    //******Public Functions******
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function checkGenesisClaimQuantity(uint256 tokenId) public view returns (uint256)  {
        return genesisClaimMap[tokenId];
    }

    function checkMintQuantity(address walletAddress) public view returns (uint256)  {
        return mintMap[walletAddress];
    }

    function genesisClaim(
        uint256 quantity,
        uint256 genesisId
    ) external payable {
        require(genesisClaimAvailable, "Claim not available!");
        require(
            genesisClaimMap[genesisId] + quantity <= individualGenesisClaimLimit,
            "You have reached individual genesis claim limit!"
        );
        uint256 startId = _nextTokenId();
        require(
            startId + quantity <= maxCount,
            "Not enough stock!"
        );
        require(
            genesisClaimCount + quantity <= genesisClaimLimit,
            "Not enough stock!"
        );
        IERC721A genesisContract = IERC721A(genesisAddress);
        require(genesisContract.ownerOf(genesisId) == msg.sender, "Invalid genesis owner!");

        uint256 totalPrice = quantity.mul(genesisClaimPrice);
        require(msg.value >= totalPrice, "Not enough money!");

        genesisClaimMap[genesisId] = genesisClaimMap[genesisId] + quantity;
        genesisClaimCount = genesisClaimCount + quantity;
        _safeMint(msg.sender, quantity);

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        emit MintSuccess(msg.sender, startId, quantity, totalPrice, "", 0);
    }

    function whiteListMint(
        uint256 quantity,
        bytes32 hash,
        bytes memory signature,
        uint256 blockHeight,
        string memory nonce
    ) external payable {
        require(mintAvailable, "Mint not available!");
        require(
            mintMap[msg.sender] + quantity <= individualMintLimit,
            "You have reached individual mint limit!"
        );
        //require(blockHeight >= block.number, "The block has expired!");
        require(!nonceMap[nonce], "Nonce already exist!");
        require(hashMint(quantity, blockHeight, nonce, "loony_face_white_list_mint") == hash, "Invalid hash!");
        require(matchAddressSigner(hash, signature), "Invalid signature!");
        uint256 totalPrice = quantity.mul(whiteListMintPrice);
        require(msg.value >= totalPrice, "Not enough money!");
        uint256 startId = _nextTokenId();
        require(
            startId + quantity <= maxCount,
            "Not enough stock!"
        );
        require(
            mintCount + quantity <= mintLimit,
            "Not enough stock!"
        );

        nonceMap[nonce] = true;
        mintCount = mintCount + quantity;
        mintMap[msg.sender] = mintMap[msg.sender] + quantity;
        _safeMint(msg.sender, quantity);

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        emit MintSuccess(msg.sender, startId, quantity, totalPrice, nonce, blockHeight);
    }

    function mint(uint256 quantity) external payable {
        require(mintAvailable, "Mint not available!");
        require(
            mintMap[msg.sender] + quantity <= individualMintLimit,
            "You have reached individual mint limit!"
        );
        uint256 totalPrice = quantity.mul(normalMintPrice);
        require(msg.value >= totalPrice, "Not enough money!");
        uint256 startId = _nextTokenId();
        require(
            startId + quantity <= maxCount,
            "Not enough stock!"
        );
        require(
            mintCount + quantity <= mintLimit,
            "Not enough stock!"
        );

        mintCount = mintCount + quantity;
        mintMap[msg.sender] = mintMap[msg.sender] + quantity;
        _safeMint(msg.sender, quantity);

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        emit MintSuccess(msg.sender, startId, quantity, totalPrice, "", 0);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    function checkLocalStakeStatus(uint256 tokenId) public view returns (uint256)  {
        return localStakeMap[tokenId];
    }

    function localStake(uint256[] memory tokenIds) external {
        require(localStakeAvailable, "local stake not available!");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "Caller is not owner!");

            if (localStakeMap[tokenId] == 0) {
                localStakeMap[tokenId] = block.timestamp;
                emit LocalStakeSuccess(msg.sender, tokenId, block.timestamp);
            }
        }
    }

    function localRedeem(uint256[] memory tokenIds) external {
        require(localRedeemAvailable, "local redeem not available!");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "Caller is not owner!");

            if (localStakeMap[tokenId] > 0) {
                localStakeMap[tokenId] = 0;
                emit LocalRedeemSuccess(msg.sender, tokenId, block.timestamp);
            }
        }
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override
    {
        require(localStakeMap[startTokenId] == 0, "This token is staking!");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    //******OperatorFilterer******
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //******Tool******
    function hashMint(uint256 quantity, uint256 blockHeight, string memory nonce, string memory code)
    private
    view
    returns (bytes32)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(msg.sender, quantity, blockHeight, nonce, code)
                )
            )
        );
        return hash;
    }

    function matchAddressSigner(bytes32 hash, bytes memory signature)
    internal
    view
    returns (bool)
    {
        return signer == recoverSigner(hash, signature);
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address){
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
    internal
    pure
    returns (
        bytes32 r,
        bytes32 s,
        uint8 v
    )
    {
        require(sig.length == 65, "Invalid signature length!");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}