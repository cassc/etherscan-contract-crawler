//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./DefaultOperatorFilterer.sol";

contract SuperordinaryFriendsCollectorsPass is ERC1155, ERC1155Supply, DefaultOperatorFilterer, Ownable {
    uint256 public constant SF_TOKEN = 0;

    string private _baseUri;
    string public name;
    string public symbol;

    bytes32 root;

    uint256 public MAX_SUPPLY = 250;

    address public constant RL_ADDRESS = 0xc9b5553910bA47719e0202fF9F617B8BE06b3A09; // Webmint

    mapping (address => uint256) addressBlockBought;
    mapping (address => uint256) public mintedSF;

    uint256[3] public PHASE_SUPPLY = [75, 75, 100];
    bool[3] public IS_PHASE_ACTIVE = [false, false, false];

    constructor(string memory _name, string memory _symbol) ERC1155("https://rl.mypinata.cloud/ipfs/QmZZWsjzcCnyrhB6YhQYaYeUuF7euABXkhixKFHiFpFexW/") {
        name = _name;
        symbol = _symbol;
        _mint(0x07e0eF7eC5d4a4FeC4E8Ce998977a298E0ACE3d5, SF_TOKEN, 1, "");
        _mint(0xEDcE3C0578292af2723e11Bd45a0baF83e5db16a, SF_TOKEN, 1, "");
        _mint(0x9EBFA34B44c799dc580F074BfFD2d94D5e25cAb5, SF_TOKEN, 1, "");
        _mint(0x8281a249028D23045d9D62880aFE425F7a221F0d, SF_TOKEN, 1, "");
        _mint(0x5341f771fC3383f22B86d0231BEb78a9174E5081, SF_TOKEN, 1, "");
        _mint(0xAA56fab6eE0Cf3580b7E560A8F35878924922868, SF_TOKEN, 1, "");
        _mint(0x71e18C339795799fE56AaF3d5c9BD4dc93bE2842, SF_TOKEN, 1, "");
        _mint(0xe6Fc3D5e548bcFb028b8d4A28F0cc3233533e7bc, SF_TOKEN, 1, "");
        _mint(0xb26EE55CBb8A190283029c43e58FC40787d69ba0, SF_TOKEN, 1, "");
        _mint(0xD221D00Cdc0595B9c4A3D8889526c6F9E8CbF220, SF_TOKEN, 1, "");
        _mint(0x275960dE6327AC921FF9580C59f6e090a64cA72d, SF_TOKEN, 1, "");
        _mint(0xaFF459aA9A4C6bACfA5D604a3C711a303c1D0C58, SF_TOKEN, 1, "");
        _mint(0xd00CeE21463BE1e7f930831197f50d6A4aD3dB50, SF_TOKEN, 1, "");
        _mint(0x01eC946B3D4C8407521fDFC9D74677db10770eb3, SF_TOKEN, 1, "");
        _mint(0x809415d7368f6de4F6076ac8A561AB85875e602F, SF_TOKEN, 1, "");
        _mint(0x60A8D2628edbc0168808CE4B8F518D04f40611b5, SF_TOKEN, 1, "");
        _mint(0xe54b7d9468d6461c6D4dCcFd136898Bc8162784F, SF_TOKEN, 1, "");
        _mint(0x3aa0a94d33CF70D35316889069A28217a8076D71, SF_TOKEN, 1, "");
        _mint(0x933BEDf323Caa78d993A50EF285F3395a9B1E4E1, SF_TOKEN, 1, "");
        _mint(0x76052d09043A75F362F48ae603e799A13549F4f9, SF_TOKEN, 1, "");
        _mint(0x2F40F2Ac99f8d85e780c66d4d98C79CDA05Db920, SF_TOKEN, 1, "");
        _mint(0x31d1b60b9461114069044b8f006049760FeF5f45, SF_TOKEN, 1, "");
    }

    // Modifier

    modifier isSecured(uint8 mintPhase) {
        require(addressBlockBought[msg.sender] < block.timestamp, 'CANNOT_MINT_ON_THE_SAME_BLOCK');
        require(tx.origin == msg.sender, 'OWNER_IS_NOT_ALLOWED_TO_MINT');
        require(mintPhase < 3, 'MINT_PHASE_IS_INVALID');
        require(IS_PHASE_ACTIVE[mintPhase], 'PHASE_IS_NOT_YET_ACTIVE');
        _;
    }

    modifier checkPhaseSupply(uint8 mintPhase, uint256 numOfTokens) {
        uint8 index = 0;
        uint256 currentPhaseSupply = 0;
        for (index = 0; index < mintPhase + 1; index++) {
            currentPhaseSupply += PHASE_SUPPLY[0];
            if (mintPhase != index) {
                continue;
            }
            require(numOfTokens + totalSupply(SF_TOKEN) <= currentPhaseSupply, 'NOT_ENOUGH_SUPPLY');
        }
        _;
    }

    // Mint Methods

    function freeMint(uint256 numOfTokens, uint8 mintPhase, bytes32[] memory proof) external isSecured(mintPhase) checkPhaseSupply(mintPhase, numOfTokens) {
        require(MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender))), "PROOF_INVALID");

        addressBlockBought[msg.sender] = block.timestamp;
        mintedSF[msg.sender] += numOfTokens;

        _mint(msg.sender, SF_TOKEN, numOfTokens, "");
    }

    // Utils

    function setBaseURI(string calldata URI) external onlyOwner {
        _baseUri = URI;
    }

    function setActivePhase(uint8 _mintPhase) external onlyOwner {
        IS_PHASE_ACTIVE[_mintPhase] = !IS_PHASE_ACTIVE[_mintPhase];
    }

    function setPhaseSupply(uint8 _mintPhase, uint256 _supply) external onlyOwner {
        MAX_SUPPLY = MAX_SUPPLY - PHASE_SUPPLY[_mintPhase] + _supply;
        PHASE_SUPPLY[_mintPhase] = _supply;
    }

    // MerkleTree Utils

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    // Essentials

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(RL_ADDRESS).transfer((balance * 600) / 10000);
        payable(msg.sender).transfer(address(this).balance);
    }

    // OPENSEA's royalties functions

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    // Override functions

    function uri(uint256 _id) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_baseUri, Strings.toString(_id)));
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}