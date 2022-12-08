//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/MonksI.sol";
import "../interfaces/MonksVXI.sol";

contract VXMonksMint is ReentrancyGuard, Ownable {
    
    bytes32 public merkleRoot;
    MonksI public monks;
    MonksVXI public monksVX;
    uint256 public newMonks = 2000;
    uint256 public price = 0.05 ether;

    bool public publicMintOpen = false;
    bool public claimingOpen = false;
    bool public whitelistOpen = false;

    mapping(address => uint256) public claimedPerWallet;

    event ClaimedMonks(address indexed _owner, uint16[] _monksIds);
    event ClaimedWhitelist(address indexed _owner, uint16[] _ids);
    event Claimed(address indexed _owner, uint16[] _ids);
    event ChangedPrice(uint256 _price);
    event MerkleRootChanged(bytes32 _merkleRoot);
    event SetContract(address _contract, string _type);
    event ChangedIdIndex(uint256 _newIndex);
    event PublicMint(address indexed _owner, uint16[] ids);
    event PublicMintToggled(bool isOpen);
    event WhiteListMintToggled(bool isOpen);
    event ClaimingToggled(bool isOpen);

    error NotOwner();
    error AlreadyMinted();
    error MaxSupplyReached();
    error WrongAmount();
    error WrongLeaf();
    error WrongProof();
    error CapReached();
    error PublicMintClosed();
    error ClaimingClosed();
    error WhiteListClosed();

    // solhint-disable-next-line
    function ClaimMonk(uint16[] calldata _tokenIds) external nonReentrant {
        if (claimingOpen == false) revert ClaimingClosed();
        uint256 i;
        uint16[] memory ids = new uint16[](_tokenIds.length * 2);
        for (i; i < _tokenIds.length; ) {
            unchecked {
                uint16 currentToken = _tokenIds[i];
                if (monks.balanceOf(msg.sender, currentToken) == 0) revert NotOwner();
                ids[i] = currentToken;
                uint256 extraIndex = _tokenIds.length + i;
                ids[extraIndex] = currentToken + 500;
                i++;
            }
        }

        monksVX.mintBatch(msg.sender, ids);
        emit ClaimedMonks(msg.sender, ids);
    }

    function claimWhitelist(
        uint16 _whitelistedAmount,
        bytes32[] calldata _merkleProof
    ) external nonReentrant {
        if (whitelistOpen == false) revert WhiteListClosed();
        //check merkle
        if (!MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender, _whitelistedAmount))))
            revert WrongProof();

        //checking how much he already minted
        if (claimedPerWallet[msg.sender] >= _whitelistedAmount) revert CapReached();
        uint16[] memory ids = new uint16[](_whitelistedAmount);
        uint256 i;
        for (i; i < _whitelistedAmount; ) {
            unchecked {
                if (newMonks >= monksVX.MAX_SUPPLY()) revert MaxSupplyReached();
                ids[i] = uint16(++newMonks);
                i++;
            }
        }

        claimedPerWallet[msg.sender] += _whitelistedAmount;
        monksVX.mintBatch(msg.sender, ids);
        emit ClaimedWhitelist(msg.sender, ids);
    }


    function publicMint(uint256 _amount) external payable nonReentrant {
        if (publicMintOpen == false) revert PublicMintClosed();
        if (newMonks + _amount > monksVX.MAX_SUPPLY()) revert MaxSupplyReached();
        require(_amount <= 10 && _amount > 0, "Max 10 mint per tx, min 1");

        uint256 totalPriceToPay;
        uint16[] memory ids = new uint16[](_amount);
        uint256 i;

        for (i; i < _amount; ) {
            unchecked {
                ids[i] = uint16(++newMonks);
                totalPriceToPay += price;
                i++;
            }
        }

        if (msg.value != totalPriceToPay) revert WrongAmount();
        
        monksVX.mintBatch(msg.sender, ids);
        emit PublicMint(msg.sender, ids);
    }


    function setMonks(MonksI _monks) external onlyOwner {
        monks = _monks;
        emit SetContract(address(_monks), "Monks");
    }

    function setVXMonks(MonksVXI _vxMonks) external onlyOwner {
        monksVX = _vxMonks;
        emit SetContract(address(_vxMonks), "MonksVX");
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
        emit ChangedPrice(_newPrice);
    }

    function setNewMonks(uint256 _newMonks) external onlyOwner {
        newMonks = _newMonks;
        emit ChangedIdIndex(_newMonks);
    }

    function setPublicMint(bool isOpen) external onlyOwner {
        publicMintOpen = isOpen;
        emit PublicMintToggled(isOpen);
    }

    function setWl(bool isOpen) external onlyOwner {
        whitelistOpen = isOpen;
        emit PublicMintToggled(isOpen);
    }

    function setClaiming(bool isOpen) external onlyOwner {
        claimingOpen = isOpen;
        emit PublicMintToggled(isOpen);
    }

    /**
     * @notice sets merkle root
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootChanged(_merkleRoot);
    }

    function withdrawEther() external onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

}