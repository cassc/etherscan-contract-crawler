// SPDX-License-Identifier: LGPL-3.0-or-later 

pragma solidity ^0.8.4;

/**
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@N%i=}[email protected]@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@@@@[email protected]@@@@@@@[email protected]@@@@K.     \@@@@@@@@@@@@@@@@@@@@@A`     [email protected]@@@@@@@@@@@@@@WHP2yuy%[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@@p:     `\[email protected]@@@H^      *[email protected]@@o      `@@@@@@@@@@@@@@@@@@@@Wi      "@@@@@@@@@@@@Ne*_         ,>#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@M-        |@@@N,        \@@@Ni,  `^[email protected]@@@@@@@@@@@@@@@@@@@@N=-  `[email protected]@@@@@@@@@@G:              :[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@S          [email protected]          [email protected]@@Ne|\[email protected]@@Nei=i5Nqul(>[email protected]@@@@Ru>\[email protected]@@@@@@@@@@K       !*^,    `[email protected]@@[email protected]@@@@H{[email protected]@@H}[email protected]@@@@@@@@@g%[email protected]@@@@@[email protected][email protected]@@@Rh}=\*[email protected]@@@@@@@
 *@@@@@@@@*          :BH           [email protected]@R,     vWR,     '        [email protected]@H-     [email protected]@@@@@@@@@u      `\[email protected]@@R,     [email protected]@%`    `[email protected]     `        :[email protected]@@@Nx~         `[email protected]@@K-     ;     [email protected]@K*`          [email protected]@@@@@
 *@@@@@@@N`           y!           [email protected]@E      :@E                 [email protected]      [email protected]@@@@@@@@@R-           ."|[email protected]@E      :@@@*      [email protected]                [email protected]@5'              [email protected]            ,@K`     .:-    :[email protected]@@@@@
 *@@@@@@@y      *.          !-      [email protected]      :@E       xAe,      [email protected]      [email protected]@@@@@@@@@@Rl_             `[email protected]      :@@@*      [email protected]       !i=,      ^WE       zEG*      :Wu        [email protected]      ,\voaE#@@@@@@@@
 *@@@@@@@!      3y         `g*      [email protected]      :@E      :[email protected]@\      \@u      [email protected]@@@@@@@@@@@@N62tr^,`        GE      :@@@*      [email protected]      [email protected]@@R       N|                  @u      [email protected]@@@@@z`         '[email protected]@@@@@@
 *@@@@@@R       [email protected]"        [email protected]      ;@E      :@E      :@@@\      \@u      [email protected]@@@@@@@@@@w(*>}3$QNR{       uE      [email protected]~      [email protected]      [email protected]@3      `BC       !((((((+\[email protected]      \@@@@@@@@Wg2s\;,      `[email protected]@@@@@
 *@@@@@@C      [email protected]@6       ,[email protected]       RE      :@E      :@@@\      \@u      [email protected]@@@@@@@@@u        ``       _RN`      `:`       [email protected]       ,^:       [email protected]"      `"***!:.`,[email protected]      \@@@@@@@C,  ,!=x^      |@@@@@@
 *@@@@@@(      >@@@v      [email protected]@@_      eO      "@H      [email protected]@@i      |@2      *@@@@@@@@@@X`              `|[email protected]@U_             `[email protected]@r               [email protected]@@Nx-              ~Wy      [email protected]@@@@@@"             [email protected]@@@@@
 *@@@@@@Q*`  `\[email protected]@@N\   `[email protected]@@@q!`  [email protected]{_   ^[email protected]@C,   ^[email protected]@@R\`  `*[email protected]  `[email protected]@@@@@@@@@@Q}*:`      `,*[email protected]@@@@Ny*,`      [email protected]@@r      -`    [email protected]@@@@@NS|"'      .~\[email protected]  `\[email protected]@@@@@@N2\:`      _*%[email protected]@@@@@@
 *@@@@@@@@[email protected]@@@@@@[email protected]@@@@@@[email protected]@@@[email protected]@@@@@[email protected]@@@@@@[email protected]@@@@[email protected]@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@@@r      [email protected]@@@@@@@@@@@@@[email protected]@@@@@@@[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@r      [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@l      [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Ni,`.;[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * in collaboration with Purebase Studio https://purebase.co/
 */

import "./erc721a/contracts/ERC721A.sol";
import 'openzeppelin-solidity/contracts/access/Ownable.sol';
import 'openzeppelin-solidity/contracts/utils/cryptography/MerkleProof.sol';
import 'openzeppelin-solidity/contracts/security/ReentrancyGuard.sol';

contract MiniSupers is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    bool public paused;
    bool public minting;
    bool public whitelistminting;
    bytes32 public whitelistMerkleRoot;
    mapping(address => uint256) public whitelistClaimed;
    uint256 public constant maxBatchSize = 10;
    uint256 public maxPublicPerWallet = 5;
    uint256 public cost = 0.069 ether;
    uint256 public constant maxSupply = 6969;
    uint256 public maxMintAmountPerTx = 5;
    string private _baseTokenURI = 'https://minisupers.io/api/nft/';
    string public provenance;

    constructor() ERC721A("Mini Supers", "MINISUPERS") {
        paused = true;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    function flipPause() public onlyOwner {
        paused = !paused;
    }
    function flipMint() public onlyOwner {
        minting = !minting;
    }
    function flipPresaleMint() public onlyOwner {
        whitelistminting = !whitelistminting;
    }
    function setItemPrice(uint256 _price) public onlyOwner {
        cost = _price;
    }
    function setNumPerMint(uint256 _max) public onlyOwner {
        maxMintAmountPerTx = _max;
    }
    function setNumPerWallet(uint256 _max) public onlyOwner {
        maxPublicPerWallet = _max;
    }
    function _leaf(string memory allowance, string memory payload) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(payload, allowance));
    }
    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, whitelistMerkleRoot, leaf);
    }

    function mintReserves(uint256 quantity) public onlyOwner {
        require(quantity % maxBatchSize == 0, "can only mint a multiple of the maxBatchSize");
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
    }

    function presaleMint(uint256 _mintAmount, uint256 _allowance, bytes32[] calldata _merkleProof) public payable callerIsUser {
        string memory payload = string(abi.encodePacked(_msgSender()));
        require(!paused, 'The contract is paused!');
        require(whitelistminting, "Whitelist Mint closed");
        require(whitelistClaimed[msg.sender] + _mintAmount <= _allowance, 'More than allowed during WL');
        require(totalSupply() + _mintAmount <= maxSupply, 'More than max supply');
        require(msg.value >= cost * _mintAmount, 'Not enough ETH');
        require(_verify(_leaf(Strings.toString(_allowance), payload), _merkleProof),'Invalid proof');
        
        whitelistClaimed[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function mint(uint256 _mintAmount) public payable callerIsUser {
        require(!paused, 'The contract is paused!');
        require(minting, "Mint closed");
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount');
        require(totalSupply() + _mintAmount <= maxSupply, 'More than max supply');
        require(msg.value >= cost * _mintAmount, 'Not enough ETH');
        require(numberMinted(msg.sender) + _mintAmount <= maxPublicPerWallet + whitelistClaimed[msg.sender], 'More than allowed per wallet');
        
        _safeMint(msg.sender, _mintAmount);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        whitelistMerkleRoot = _merkleRoot;
    }
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    function setProvenance(string memory hash) public onlyOwner {
        provenance = hash;
    }
    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}