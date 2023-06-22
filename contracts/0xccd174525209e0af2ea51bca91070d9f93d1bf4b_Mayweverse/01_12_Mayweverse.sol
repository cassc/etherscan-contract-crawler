// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Mayweverse is ERC1155, Ownable {
    using Strings for uint256;

    mapping(uint256 => uint256) public maxSupply;

    mapping(uint256 => uint256) public totalSupplyReached;

    mapping(address => uint256) public wLBalanceOf;

    mapping(address => uint256) public publicBalanceOf;

    // workflow : 0 -> mint close / 1 -> mint private / -> 2 mint public
    uint256 public workflow = 0;

    uint256 public _supply = 1000;

    uint256 public privatePrice = 0.3 ether;

    uint256 public publicPrice = 0.3 ether;

    uint256 public maxMintPrivate = 3;

    uint256 public modulo = 6;

    uint256 public maxMintPublic = 3;

    uint256 public minted;

    bytes32 public merkleRoot;

    string public baseURI;

    string public notRevealedUri;

    bool public isRevealed;

    string public _name = 'MAYWEVERSE';

    string public _symbol = 'MWV';

    constructor() ERC1155("") {
        for (uint256 i = 1; i <= 5; i++) {
            maxSupply[i] = _supply;
        }

    }

    event ChangeBaseURI(string _baseURI);
    event PrivateMint(address indexed _minter, uint256 _amount, uint256 _price);
    event PublicMint(address indexed _minter, uint256 _amount, uint256 _price);

    function privateMint(uint256 amount, bytes32[] calldata _merkleProof)
        public
        payable
    {
        require(workflow == 1, "Mint : private mint not open");
        require(msg.value >= privatePrice * amount, "Price : invalid price");
        require(
            wLBalanceOf[msg.sender] + amount <= maxMintPrivate,
            "NFT : invalid amount"
        );
        require(amount > 0, "invalid amount ");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "VERIFY: You are not whitelisted"
        );

        for (uint256 i = 1; i <= amount; i++) {
            _randomMint(1);
            wLBalanceOf[msg.sender]++;
        }
        emit PrivateMint(msg.sender, amount, msg.value);
    }

    function publicMint(uint256 amount) public payable {
        require(workflow == 2, "Mint : public mint not open");
        require(msg.value >= publicPrice * amount, "Price : invalid price");
        require(publicBalanceOf[msg.sender] + amount <= maxMintPublic, "NFT : invalid amount");
        require(amount > 0, "invalid amount ");

        for (uint256 i = 1; i <= amount; i++) {
            _randomMint(1);
            publicBalanceOf[msg.sender]++;
        }
        emit PublicMint(msg.sender, amount, msg.value);
    }

    function _randomMint(uint256 amount) internal {
        uint256 temp = randomSource(minted) % 6;
        uint256 _seed;
        if (temp < 1) {
            _seed = 1;
        } else {
            _seed = temp;
        }
        if (totalSupplyReached[_seed] >= maxSupply[_seed])
            return _randomMint(amount);
        _mint(address(msg.sender), _seed, 1, "");
        minted++;
    }

    function uri(uint256 _id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (isRevealed == false) {
            return notRevealedUri;
        }
        return string(abi.encodePacked(baseURI, _id.toString(), ".json"));
    }

    //-----------NFT MANAGEMENT-------------//

    function updateMaxMint(uint256 _private, uint256 _public)
        external
        onlyOwner
    {
        maxMintPrivate = _private;
        maxMintPublic = _public;
    }

    function updateSupply(uint256 tokenID, uint256 newSupply)
        external
        onlyOwner
    {
        maxSupply[tokenID] = newSupply;
    }

    function reveal() public onlyOwner {
        isRevealed = true;
    }

    function setNoReveleadURI(string memory _notRevealedUri) public onlyOwner {
        notRevealedUri = _notRevealedUri;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }


    //-----------PRICE MANAGEMENT-------------//
    function updatePrivatePrice(uint256 _newPrice) public onlyOwner {
        privatePrice = _newPrice;
    }

    function updatePublicPrice(uint256 _newPrice) public onlyOwner {
        publicPrice = _newPrice;
    }

    function randomSource(uint256 _seed) internal view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    tx.origin,
                    blockhash(block.number - 1),
                    block.timestamp,
                    _seed
                )
            )
        ) ^ _seed;

        return random;
    }

    //----------WORKFLOW MANAGEMENT-----------//
    function restart() external onlyOwner {
        workflow = 0;
    }

    function setUpPrivate() external onlyOwner {
        workflow = 1;
    }

    function setUpPublic() external onlyOwner {
        workflow = 2;
    }

    function getSaleStatus() public view returns (uint256) {
        return workflow;
    }

    //-----------MERKLE MANAGEMENT-------------//

    function hasWhitelist(bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }

    //---------------- OTHER ----------------//

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 halfOne = (balance * 40) / 100;
        uint256 halfTwo = balance - halfOne;
        payable(address(0x7c7343FbBbBe598d00293F62a209e8B0581bb47F)).transfer(
            halfOne
        );
        payable(address(0x537653d82060875550EC201F0d355DC6F7D0e237)).transfer(
            halfTwo
        );
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }
}