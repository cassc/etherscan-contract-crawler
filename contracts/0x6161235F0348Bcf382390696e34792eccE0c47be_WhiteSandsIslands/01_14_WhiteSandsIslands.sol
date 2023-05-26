//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WhiteSandsIslands is ERC721Enumerable, Ownable {
    using Strings for uint256;

    enum Phases {
        PHASE_1, // Whitelist
        PHASE_2, // Parcel Pass Holders
        PHASE_3 // Public Phase
    }

    Phases public phase = Phases.PHASE_1;

    address public constant FEE_RECEIVER =
        0x814858Ad31778589a2049b3399963fB3ba942c76;

    uint256 public constant MAX_SUPPLY = 250;

    bytes32 public whitelistMerkleRoot;

    uint256 public reimbursement = 0.1 ether;
    uint256 public constant PUBLIC_MINT_PRICE = 5 ether;

    address private immutable parcelPassContract;

    mapping(address => uint256) private maxMintsPerAddress;

    string private baseURI;

    modifier noContracts(address account_) {
        uint256 size;
        assembly {
            size := extcodesize(account_)
        }
        require(size == 0, "caller-is-contract");
        _;
    }

    constructor(address parcelPassContract_)
        // name, symbol
        ERC721("White Sands Islands", "WSI")
    {
        parcelPassContract = parcelPassContract_;
        _safeMint(FEE_RECEIVER, 1);
    }

    function updateWhitelistMerkleRoot(bytes32 newMerkleRoot_)
        external
        onlyOwner
    {
        whitelistMerkleRoot = newMerkleRoot_;
    }

    function getCurrentMintPrice() external view returns (uint256) {
        return _getMintPrice();
    }

    function whitelistedMint(bytes32[] calldata merkleProof_)
        external
        payable
        noContracts(msg.sender)
    {
        address _user = msg.sender;

        require(phase == Phases.PHASE_1, "invalid-mint-phase");
        require(totalSupply() + 1 <= MAX_SUPPLY, "max-supply-reached");
        require(maxMintsPerAddress[_user] == 0, "max-mint-limit");

        bool isWhitelisted = MerkleProof.verify(
            merkleProof_,
            whitelistMerkleRoot,
            keccak256(abi.encodePacked(_user))
        );

        require(isWhitelisted, "invalid-proof");

        require(msg.value == _getMintPrice(), "incorrect-ether-value");

        if (totalSupply() < MAX_SUPPLY) {
            maxMintsPerAddress[_user]++;
            _safeMint(_user, totalSupply() + 1);
        }
    }

    function parcelPassMint() external payable noContracts(msg.sender) {
        address _user = msg.sender;

        require(phase == Phases.PHASE_2, "invalid-mint-phase");
        require(totalSupply() + 1 <= MAX_SUPPLY, "max-supply-reached");

        uint256 parcelPassBalance = IERC721Enumerable(parcelPassContract)
            .balanceOf(_user);

        require(parcelPassBalance > 0, "no-pass-held");

        require(msg.value == _getMintPrice(), "incorrect-ether-value");

        if (totalSupply() < MAX_SUPPLY) {
            _safeMint(_user, totalSupply() + 1);
        }
    }

    function publicMint() external payable noContracts(msg.sender) {
        address _user = msg.sender;

        require(phase == Phases.PHASE_3, "invalid-mint-phase");
        require(totalSupply() + 1 <= MAX_SUPPLY, "max-supply-reached");
        require(msg.value == _getMintPrice(), "incorrect-ether-value");

        if (totalSupply() < MAX_SUPPLY) {
            _safeMint(_user, totalSupply() + 1);
        }
    }

    function setPhase(Phases newPhase_) external onlyOwner {
        phase = newPhase_;
    }

    function setBaseURI(string memory newURI_) external onlyOwner {
        baseURI = newURI_;
    }

    function setReimbursement(uint256 newReimbursement_) external onlyOwner {
        require(
            newReimbursement_ < ((PUBLIC_MINT_PRICE * 900) / 1000),
            "invalid-reimbursement"
        );
        reimbursement = newReimbursement_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId_), "non-existent-token");
        string memory _base = _baseURI();
        return string(abi.encodePacked(_base, tokenId_.toString()));
    }

    function _getMintPrice() internal view returns (uint256 _price) {
        if (phase == Phases.PHASE_3) _price = PUBLIC_MINT_PRICE;
        else {
            // apply 10% discount for whitelisted users
            // or parcel pass holders
            _price = (PUBLIC_MINT_PRICE * 900) / 1000;
        }
        // subtract oculus reimbursment
        _price -= reimbursement;
    }

    function withdraw() external {
        uint256 _balance = address(this).balance;
        payable(FEE_RECEIVER).transfer(_balance);
    }
}