// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/**
      _____                   _______                   _____                    _____                    _____                    _____          
     |\    \                 /::\    \                 /\    \                  /\    \                  /\    \                  /\    \         
     |:\____\               /::::\    \               /::\    \                /::\    \                /::\    \                /::\    \        
     |::|   |              /::::::\    \             /::::\    \               \:::\    \              /::::\    \              /::::\    \       
     |::|   |             /::::::::\    \           /::::::\    \               \:::\    \            /::::::\    \            /::::::\    \      
     |::|   |            /:::/~~\:::\    \         /:::/\:::\    \               \:::\    \          /:::/\:::\    \          /:::/\:::\    \     
     |::|   |           /:::/    \:::\    \       /:::/  \:::\    \               \:::\    \        /:::/__\:::\    \        /:::/__\:::\    \    
     |::|   |          /:::/    / \:::\    \     /:::/    \:::\    \              /::::\    \      /::::\   \:::\    \       \:::\   \:::\    \   
     |::|___|______   /:::/____/   \:::\____\   /:::/    / \:::\    \    ____    /::::::\    \    /::::::\   \:::\    \    ___\:::\   \:::\    \  
     /::::::::\    \ |:::|    |     |:::|    | /:::/    /   \:::\ ___\  /\   \  /:::/\:::\    \  /:::/\:::\   \:::\    \  /\   \:::\   \:::\    \ 
    /::::::::::\____\|:::|____|     |:::|    |/:::/____/  ___\:::|    |/::\   \/:::/  \:::\____\/:::/__\:::\   \:::\____\/::\   \:::\   \:::\____\
   /:::/~~~~/~~       \:::\    \   /:::/    / \:::\    \ /\  /:::|____|\:::\  /:::/    \::/    /\:::\   \:::\   \::/    /\:::\   \:::\   \::/    /
  /:::/    /           \:::\    \ /:::/    /   \:::\    /::\ \::/    /  \:::\/:::/    / \/____/  \:::\   \:::\   \/____/  \:::\   \:::\   \/____/ 
 /:::/    /             \:::\    /:::/    /     \:::\   \:::\ \/____/    \::::::/    /            \:::\   \:::\    \       \:::\   \:::\    \     
/:::/    /               \:::\__/:::/    /       \:::\   \:::\____\       \::::/____/              \:::\   \:::\____\       \:::\   \:::\____\    
\::/    /                 \::::::::/    /         \:::\  /:::/    /        \:::\    \               \:::\   \::/    /        \:::\  /:::/    /    
 \/____/                   \::::::/    /           \:::\/:::/    /          \:::\    \               \:::\   \/____/          \:::\/:::/    /     
                            \::::/    /             \::::::/    /            \:::\    \               \:::\    \               \::::::/    /      
                             \::/____/               \::::/    /              \:::\____\               \:::\____\               \::::/    /       
                              ~~                      \::/____/                \::/    /                \::/    /                \::/    /        
                                                                                \/____/                  \/____/                  \/____/                                                                                                                                                                 
 */

import "./lib/ERC721Y.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract IGYogie {
    function stakeYogie(uint256 yogieId, address sender) external {}
    function unstakeYogie(uint256 yogieId, address sender) external {}
    function updateYogieStakeTime(uint256 yogieId, address sender) external {}
    function getStakeLastClaimed(uint256 yogieId) external view returns (uint256) {}
    function getStakeOwner(uint256 yogieId) external view returns (address) {}
    function balanceOf(address owner) public view returns (uint256) {}
    function totalSupply() public view returns (uint256) {}
    function ownerOf(uint256 tokenId) public view returns (address) {}
}

abstract contract IGemies is IERC20 {
    function getEcoSystemBalance(address user) external view returns (uint256) {}
    function spendEcosystemBalance(uint256 amount, address user) external {}
}

contract Yogies is ERC721Y, Ownable {
    using Strings for uint256;

    /** === ERC721 === */
    address public openseaProxyRegistryAddress;
    string public baseURIString = "https://storage.googleapis.com/yogies-assets/metadata/yogies/";
    bool public isFrozen = false;

    modifier notFrozen() {
        require(!isFrozen, "CONTRACT FROZEN");
        _;
    }

    /**  General info === */
    uint256 public totalYogies = 4444;

    /** === Free mint === */
    bool public isOpen;
    uint256 public freeMintTotal = 3333;
    bytes32 public merkleRoot = 0x1d7dad1aa26fcd105a60218c4addd0538c7b3778ef26cd688db070133f0f971c;

    /** === Vault === */
    bool public vaultOpened = false;
    uint256 public vaultReleasedCounter;
    uint256 public viyReleaseCounter;
    uint256 public vaultStartPoint;
    uint256 public viyStartPoint = 4334;
    uint256 public vaultPriceYogie = 100 ether;
    uint256 public vaultPriceVIY = 700 ether;

    /** === Yogies contracts === */
    IGemies public gemies;
    IGYogie public gYogies;
    mapping(address => bool) public yogiesOperator;

    modifier onlyOperator() {
        require(yogiesOperator[msg.sender] || msg.sender == owner(), "Sender not authorized");
        _;
    }

    /** === Events === */
    event StakeYogie(address indexed staker, uint256 indexed yogie);
    event UnstakeYogie(address indexed staker, uint256 indexed yogie);
    event ClaimGemies(address indexed claimer, uint256 indexed amount);

    event setBaseURIEvent(string indexed baseURI);
    event ReceivedEther(address indexed sender, uint256 indexed amount);

    constructor(
        address _openseaProxyRegistryAddress,
        //address _gemies,
        address _gYogies
    ) ERC721Y("Yogies", "Yogies") Ownable() {
        openseaProxyRegistryAddress = _openseaProxyRegistryAddress;

        //gemies = IGemies(_gemies);
        gYogies = IGYogie(_gYogies);
    }

    /*** === Staking core === */
    function _stakeYogie(uint256 yogieId, address sender) internal {
        require(_exists(yogieId), "Yogie does not exist");
        require(_ownershipOf(yogieId).stakeLastClaimTime == 0, "Yogie already staked");
        require(_ownershipOf(yogieId).addr == sender, "Sender does not own yogie");

        _approve(address(0), yogieId, sender);
        _setStakeTime(yogieId);        
        emit Transfer(sender, address(this), yogieId);
    }

    function _unstakeYogie(uint256 yogieId, address sender) internal {
        require(_exists(yogieId), "Yogie does not exist");
        require(_ownershipOf(yogieId).stakeLastClaimTime != 0, "Yogie not staked");
        require(_ownershipOf(yogieId).addr == address(this), "Yogie not staked in contract");
        require(_ownerships[yogieId].addr == sender, "Sender does not own yogie");

        _deleteStakeTime(yogieId);        
        emit Transfer(address(this), sender, yogieId);
    }
    
    /** === Staking interface === */
    function stakeYogie(uint256 yogie, address sender) external onlyOperator {
        _stakeYogie(yogie, sender);
    }

    function unstakeYogie(uint256 yogie, address sender) external onlyOperator {
        _unstakeYogie(yogie, sender);
    }

    /** === Minting === */
    function freeMint(bytes32[] calldata proof, address caller) external onlyOperator {
        bytes32 leaf = keccak256(abi.encodePacked(caller));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "User not whitelisted");

        require(_numberMinted(caller) == 0, "Yogie already claimed");
        require(totalSupply() < freeMintTotal, "No more yogies left");
        require(isOpen, "Freemint closed");

        _mint(caller, 1, "", false);
    }
    
    function mintTo(address _to, uint256 amount) external onlyOperator {
        require(totalSupply() < totalYogies, "Total yogies reached");
        _mint(_to, amount, "", false);
    }

    /** === vault === */

    /// @dev modified transferFrom
    function _unlockFromVault(address to, uint256 tokenId) internal {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != address(this)) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[address(this)].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;            

            // Staked yogies can in no circumstance be transfered
            require(currSlot.stakeLastClaimTime == 0, "Cannot transfer stake yogie");

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = address(this);                    
                }
            }
        }

        emit Transfer(address(this), to, tokenId);
    }

    function unlockFromVault(address to, uint256 tokenId) external onlyOperator {
        _unlockFromVault(to, tokenId);
    }

    function lockYogiesInVault() external onlyOwner {
        require(totalSupply() < totalYogies, "Total yogies reached");
        isOpen = false;
        vaultOpened = true;
        uint256 left = totalYogies - totalSupply();
        vaultStartPoint = _currentIndex;
        _mint(address(this), left, "", false);
    }

    function unlockYogieFromVault() external {
        require(vaultOpened, "Vault closed");
        require(getYogiesLeftInVault() > 0, "Vault empty");
        require(gemies.getEcoSystemBalance(msg.sender) >= vaultPriceYogie, "Not enough gemies");
        
        gemies.spendEcosystemBalance(vaultPriceYogie, msg.sender);
        _unlockFromVault(msg.sender, getNextVaultId());       

        vaultReleasedCounter++;
    }

    function unlockVIYFromVault() external {
        require(vaultOpened, "Vault closed");
        require(getVIYsLeftInVault() > 0, "Vault empty");
        require(gemies.getEcoSystemBalance(msg.sender) >= vaultPriceVIY, "Not enough gemies");
        
        gemies.spendEcosystemBalance(vaultPriceVIY, msg.sender);
        _unlockFromVault(msg.sender, getNextVIYId());

        viyReleaseCounter++;
    }

    /** === View Staking === */
    function getYogiesOfUser(address user)
        external
        view
        returns (uint256[] memory) {
            uint256 userBalance = balanceOf(user);
            uint256[] memory userYogies = new uint256[] (userBalance);
            uint256 counter;

            for (uint i = 1; i <= totalSupply(); i++) {                
                address _owner = _ownershipOf(i).addr;
                if (_owner == user) {
                    userYogies[counter] = i;
                    counter++;
                }
            }

            return userYogies;
        }

    function getGYogiesOfUser(address user)
        external
        view
        returns (uint256[] memory) {
            uint256 userBalance = gYogies.balanceOf(user);
            uint256[] memory userYogies = new uint256[] (userBalance);
            uint256 counter;

            for (uint i = 1; i <= gYogies.totalSupply(); i++) {                
                address _owner = gYogies.ownerOf(i);
                if (_owner == user) {
                    userYogies[counter] = i;
                    counter++;
                }
            }

            return userYogies;
        }

    function getStakedYogiesOfUser(address user)
        external
        view
        returns (uint256[] memory) {
            uint256 userBalance = balanceOf(user);
            uint256[] memory userYogies = new uint256[] (userBalance);
            uint256 counter;

            for (uint i = 1; i <= totalSupply(); i++) {                
                address _owner = _ownerships[i].addr;
                uint256 stakeTime = _ownerships[i].stakeLastClaimTime;
                if (_owner == user && stakeTime != 0) {
                    userYogies[counter] = i;
                    counter++;
                }
            }

            return userYogies;
        }

    function getStakedGYogiesOfUser(address user)
        external
        view
        returns (uint256[] memory) {
            uint256 userBalance = gYogies.balanceOf(user);
            uint256[] memory userYogies = new uint256[] (userBalance);
            uint256 counter;

            for (uint i = 1; i <= gYogies.totalSupply(); i++) {                
                address _owner = gYogies.getStakeOwner(i);
                uint256 stakeTime = gYogies.getStakeLastClaimed(i);
                if (_owner == user && stakeTime != 0) {
                    userYogies[counter] = i;
                    counter++;
                }
            }

            return userYogies;
        }

    function areYogiesStaked(uint256[] calldata yogies)
        external
        view
        returns(bool[] memory) {
            bool[] memory areStaked = new bool[] (yogies.length);
            for (uint i = 0; i < yogies.length; i++) {                
                areStaked[i] = _ownershipOf(yogies[i]).stakeLastClaimTime != 0;
            }

            return areStaked;
        }   

    function areGYogiesStaked(uint256[] calldata yogies)
        external
        view
        returns(bool[] memory) {
            bool[] memory areStaked = new bool[] (yogies.length);
            for (uint i = 0; i < yogies.length; i++) {                
                areStaked[i] = gYogies.getStakeLastClaimed(yogies[i]) != 0;
            }

            return areStaked;
        }

    function getYogiesRealOwner(uint256 yogie)
        external
        view
        returns (address) {
            if (_exists(yogie)) {
                return _ownerships[yogie].addr;
            }
            return address(0);
        }

    function getGYogiesRealOwner(uint256 yogie)
        external
        view
        returns (address) {
            return gYogies.getStakeOwner(yogie);
        }

    function getStakeLastClaimedFromYogie(uint256 yogie)
        external
        view 
        returns (uint256) {
            return _ownershipOf(yogie).stakeLastClaimTime;
        }

    function nextYogieId()
        external
        view
        returns (uint256) {
            return _currentIndex;
        }

    /** === View vault === */
    function getYogiesLeftInVault() public view returns(uint256) {
        return viyStartPoint - vaultStartPoint - vaultReleasedCounter;
    }

    function getNextVaultId() public view returns(uint256) {
        return vaultStartPoint + vaultReleasedCounter;
    }

    function getVIYsLeftInVault() public view returns(uint256) {
        return (totalYogies + 1) - viyStartPoint - viyReleaseCounter;
    }

    function getNextVIYId() public view returns(uint256) {
        return viyStartPoint + viyReleaseCounter;
    }

    /** === View freemint === */
    function freeMintsLeft() external view returns(uint256) {
        if (totalSupply() > freeMintTotal)
            return 0;
        else
            return freeMintTotal - totalSupply();
    }

    /** === View erc721 == */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURIString, tokenId.toString(), ".json"));     
    }

    function numberMinted(address minter) external view returns(uint256) {
        return _numberMinted(minter);
    }

    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Create an instance of the ProxyRegistry contract from Opensea
        ProxyRegistry proxyRegistry = ProxyRegistry(openseaProxyRegistryAddress);
        // whitelist the ProxyContract of the owner of the Yogies

        if (openseaProxyRegistryAddress != address(0)) {
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }

            if (openseaProxyRegistryAddress == operator) {
                return true;
            }
        }
        
        return super.isApprovedForAll(owner, operator);
    }

    /*** === Only owner === */
    function setBaseURI(string memory _newBaseURI) external onlyOwner notFrozen {
        baseURIString = _newBaseURI;
        emit setBaseURIEvent(_newBaseURI);
    }

    function setGYogies(address newGYogies) external onlyOwner notFrozen {
        gYogies = IGYogie(newGYogies);
    }

    function setGemies(address newGemies) external onlyOwner notFrozen {
        gemies = IGemies(newGemies);
    }

    function setYogiesOperator(address _operator, bool isOperator)
        external
        onlyOwner {
            yogiesOperator[_operator] = isOperator;
        }

    function setMerkleRoot(bytes32 newRoot) external onlyOwner notFrozen {
        merkleRoot = newRoot;
    }

    function setIsOpen(bool newIsOpen) external onlyOwner notFrozen {
        isOpen = newIsOpen;
    }

    function setVaultOpened(bool newOpened) external onlyOwner notFrozen {
        vaultOpened = newOpened;
    }

    function setVaultPriceYogie(uint256 newPrice) external onlyOwner notFrozen {
        vaultPriceYogie = newPrice;
    }

    function setVaultPriceVIY(uint256 newPrice) external onlyOwner notFrozen {
        vaultPriceVIY = newPrice;
    }

    function setVaultStartPoint(uint256 newStart) external onlyOwner notFrozen {
        vaultStartPoint = newStart;
    }

    function setVIYStartPoint(uint256 newStart) external onlyOwner notFrozen {
        viyStartPoint = newStart;
    }

    function setOwnerExplicit(uint256 yogieId) external onlyOwner {
        _setOwnerExplicit(yogieId);
    }

    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }

    function approveForAll(address operator, bool approved) external onlyOwner {
        _operatorApprovals[address(this)][operator] = approved;
    }
}