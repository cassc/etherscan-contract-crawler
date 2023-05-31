// SPDX-License-Identifier: MIT
//  ___   _  __   __  ______   _______  _______  _______  ___  
// |   | | ||  | |  ||      | |   _   ||       ||   _   ||   | 
// |   |_| ||  | |  ||  _    ||  |_|  ||  _____||  |_|  ||   | 
// |      _||  |_|  || | |   ||       || |_____ |       ||   | 
// |     |_ |       || |_|   ||       ||_____  ||       ||   | 
// |    _  ||       ||       ||   _   | _____| ||   _   ||   | 
// |___| |_||_______||______| |__| |__||_______||__| |__||___| 
//  __   __  ___   __    _  _______  _______  ______           
// |  |_|  ||   | |  |  | ||       ||       ||    _ |          
// |       ||   | |   |_| ||_     _||    ___||   | ||          
// |       ||   | |       |  |   |  |   |___ |   |_||_         
// |       ||   | |  _    |  |   |  |    ___||    __  |        
// | ||_|| ||   | | | |   |  |   |  |   |___ |   |  | |        
// |_|   |_||___| |_|  |__|  |___|  |_______||___|  |_|        

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface Kudasai {
    function mintKudasai(address _to, uint256 _quantity) external;
    function mintReserve(address _to, uint256[] memory _ids) external;
}
interface Hidden {
    function check(address _to, uint256 _quantity, bytes32 _code) external view returns (bool);
}

contract KudasaiMinter is Ownable {
    mapping(address => mapping(uint256 => uint256)) public kudasaiCounter;
    uint256 public kantsuCounter;
    mapping(uint256 => bool) public kudasaiHolderClaimed;
    mapping(uint256 => bool) public ticketHolderClaimed;
    uint256 private immutable _maxWalletPerToken;
    address private immutable _onchainKudasai;
    address private immutable _ticketNFT;
    address private immutable _kudasaiNFT;
    address private _hidden;
    uint256 public proofRound;
    bytes32 public kudasaiListMerkleRoot;
    uint256 public mintCost = 0.1 ether;

    constructor(uint256 maxWalletPerToken_, address onchainKudasai_, address kudasaiNFT_, address ticketNFT_, bytes32 kudasaiListMerkleRoot_) {
        _maxWalletPerToken = maxWalletPerToken_;
        _onchainKudasai = onchainKudasai_;
        _kudasaiNFT = kudasaiNFT_;
        _ticketNFT = ticketNFT_;
        kudasaiListMerkleRoot = kudasaiListMerkleRoot_;
    }

    modifier validateKudasaiAddress(bytes32[] calldata _merkleProof) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, kudasaiListMerkleRoot, leaf), "You are not a Kudasai list");
        _;
    }
    
    modifier onlyKudasaiHolder(uint256[] memory _ids) {
        for (uint256 i = 0; i < _ids.length; i++) {
            require(kudasaiHolderClaimed[_ids[i]] == false, "Already claimed");
            require(IERC721(address(_onchainKudasai)).ownerOf(_ids[i]) == msg.sender, "You do not have Kudasai NFTs");
            kudasaiHolderClaimed[_ids[i]] = true;
        }
        _;
    }
    
    modifier onlyTicketHolder(uint256[] memory _ids) {
        for (uint256 i = 0; i < _ids.length; i++) {
            require(ticketHolderClaimed[_ids[i]] == false, "Already claimed");
            require(IERC721(address(_ticketNFT)).ownerOf(_ids[i]) == msg.sender, "You do not have Kudasai NFTs");
            ticketHolderClaimed[_ids[i]] = true;
        }
        _;
    }

    modifier isNotContract() {
        require(tx.origin == msg.sender, "Reentrancy Guard is watching");
        _;
    }

    function setKudasaiListMerkleRoot(bytes32 _merkleRoot, uint256 _round, uint256 _mintCost) external onlyOwner {
        kudasaiListMerkleRoot = _merkleRoot;
        mintCost = _mintCost;
        proofRound = _round;
    }

    function setHidden(address _contract) external onlyOwner {
        _hidden = _contract;
    }

    function refreshHidden() external onlyOwner {
        _hidden = address(0);
    }

    function banbanban(uint256[] memory _ids) external onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            kudasaiHolderClaimed[_ids[i]] = true;
        }
    }

    function agemasu(uint256[] memory _ids, uint256 _quantity) external onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            address owner = IERC721(address(_onchainKudasai)).ownerOf(_ids[i]);
            Kudasai(_kudasaiNFT).mintKudasai(owner, _quantity);
        }
    }

    function kantsuEnable() view public returns(bool) {
        if (kantsuCounter < 10) {
            return true;
        }
        return false;
    }

    function kantsu(uint256 _quantity, bytes32 _code) external payable isNotContract {
        require(msg.value == mintCost * _quantity, "Mint cost is insufficient");
        require(_hidden != address(0) && Hidden(_hidden).check(msg.sender, _quantity, _code), "Your address is Blacklisted!");
        require(kudasaiCounter[msg.sender][proofRound] + _quantity <= _maxWalletPerToken, "No More Kudasai");
        require(kantsuEnable(), "No More Kantsu");

        kudasaiCounter[msg.sender][proofRound] += _quantity;
        kantsuCounter++;
        Kudasai(_kudasaiNFT).mintKudasai(msg.sender, _quantity);
    }

    function holderClaim(uint256[] memory _ids) external onlyKudasaiHolder(_ids) isNotContract {
        Kudasai(_kudasaiNFT).mintReserve(msg.sender, _ids);
        for (uint256 i = 0; i < _ids.length; i++) {
            IERC721(address(_onchainKudasai)).safeTransferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), _ids[i]);
        }
    }

    function ticketClaim(uint256[] memory _ids) external onlyTicketHolder(_ids) isNotContract {
        Kudasai(_kudasaiNFT).mintKudasai(msg.sender, _ids.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            IERC721(address(_ticketNFT)).safeTransferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), _ids[i]);
        }
    }

    function kudasai(uint256 _quantity, bytes32[] calldata _proof) external payable validateKudasaiAddress(_proof) isNotContract {
        require(msg.value == mintCost * _quantity, "Mint cost is insufficient");
        require(kudasaiCounter[msg.sender][proofRound] + _quantity <= _maxWalletPerToken, "No More Kudasai");

        kudasaiCounter[msg.sender][proofRound] += _quantity;
        Kudasai(_kudasaiNFT).mintKudasai(msg.sender, _quantity);
    }

    function ownerMint(uint256 _quantity) external onlyOwner {
        Kudasai(_kudasaiNFT).mintKudasai(owner(), _quantity);
    }

    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}