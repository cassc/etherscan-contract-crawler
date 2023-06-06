//
// MetaGeckos Genesis
// https://entities.wtf
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./@rarible/royalties/contracts/LibPart.sol";
import "./@rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "./nttz.sol";

contract MetaGeckos_0 is Ownable, AccessControl, ERC721Enumerable, RoyaltiesV2Impl{
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    using SafeMath for uint256;
    mapping(address => uint256) public balanceOG;
    mapping(address => uint256) public snapshotUsers;
    string public METAGECKOS_0_PROVENANCE = "";
    uint public constant MAX_GECKOS = 4000;
    bool public hasSaleStarted = false;
    string private _baseTokenURI;
    string private _baseContractURI;
    uint96 public constant royaltyFeeBps = 1000; // 10%
    address payable public payoutAddress;
    NTTZToken public nttzToken;

    //Events
    event MetaGeckoMinted(address user, uint256 numMetaGeckos);

    constructor(string memory baseTokenURI, string memory baseContractURI, address manager) ERC721("MetaGeckos Genesis", "MGEX0") {
        setBaseURI(baseTokenURI);
        _baseContractURI = baseContractURI;
        payoutAddress = payable(msg.sender);
        _setupRole(MANAGER_ROLE, manager);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    function nttz_SetAddress(address _nttz) external onlyOwner {
		nttzToken = NTTZToken(_nttz);
	}
    
    function reserveTreasury(uint256 numTreasuryMetaGeckos) public onlyOwner  {
        uint currentSupply = totalSupply();
        require(totalSupply() + numTreasuryMetaGeckos <= 30, "Exceeded treasury reserved supply");
        require(hasSaleStarted == false, "Sale has already started");
        uint256 index;
        address _to = msg.sender;
        // Reserved for Entities treasury and giveaways
        for (index = 0; index < numTreasuryMetaGeckos; index++) {
            _safeMint(_to, currentSupply + index);
            nttzToken.updateRewardOnMint(_to, balanceOG[_to]);
            balanceOG[_to]++;
            setRoyalties(index, payoutAddress, royaltyFeeBps);

    }
    emit MetaGeckoMinted(msg.sender, numTreasuryMetaGeckos);
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }
    
    function setContractURI(string memory _contractURI) public onlyOwner {
        _baseContractURI = _contractURI;    
    }

    function contractURI() public view returns (string memory) {
        return _baseContractURI;
    }
    
    function burnNTTZ(address _from, uint256 _amount) public {
		nttzToken.burn(_from, _amount);
	}
	
    function burnGecko(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "One cannot burn what one does not own");
            _burn(tokenId);
    }

    function mgexTokenBalance(address _owner) public view returns(uint){
        return balanceOf(_owner);
    }

    function addSnapshotUser(address _to, uint256 _NumberOfGeckos) public {
        require(hasRole(MANAGER_ROLE, msg.sender), "Caller is not a manager");
        snapshotUsers[_to] = _NumberOfGeckos;
     }
     
    function tokenOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    
     function setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) internal {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
    
    function setRaribleRoyaltyWallet(address payable royaltyWallet) public onlyOwner {
        payoutAddress = royaltyWallet;
    }

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
	
	function nttzClaimRewards() external {
		nttzToken.updateReward(msg.sender, address(0), 0);
		nttzToken.getReward(msg.sender);
	}
	
	function nttzClaimContribRewards() external {
		nttzToken.updateContribReward(msg.sender);
		nttzToken.getReward(msg.sender);
	}

	function transferFrom(address from, address to, uint256 tokenId) public override {
		nttzToken.updateReward(from, to, tokenId);
		if (tokenId < 4000)
		{
			balanceOG[from]--;
			balanceOG[to]++;
		}
		ERC721.transferFrom(from, to, tokenId);
	}

	function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
		nttzToken.updateReward(from, to, tokenId);
		if (tokenId < 4000)
		{
			balanceOG[from]--;
			balanceOG[to]++;
		}
		ERC721.safeTransferFrom(from, to, tokenId, _data);
	}

    function claimMetaGecko(uint256 numMetaGeckos) public {
        uint currentSupply = totalSupply();
        address _to = msg.sender;
        require(currentSupply < MAX_GECKOS, "Minting has ended");
        require(hasSaleStarted == true, "Minting has not yet started");
        require(numMetaGeckos <= snapshotUsers[_to], "Exceeds authorized claim quantity");
        require(numMetaGeckos <= 20, "Maximum of 20 mints per transaction");
        //  require(currentSupply + numMetaGeckos <= MAX_GECKOS, "Not enough available geckos");
    
    uint256 index;
    for (index = 0; index < numMetaGeckos; index++) {
        _safeMint(_to, currentSupply + index);
        nttzToken.updateRewardOnMint(_to, 1);
        balanceOG[_to]++;
        setRoyalties(index, payoutAddress, royaltyFeeBps);
        
    }
        snapshotUsers[_to]=snapshotUsers[_to] - numMetaGeckos;
        emit MetaGeckoMinted(_to, numMetaGeckos);	     
    }

}