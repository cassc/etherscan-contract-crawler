// SPDX-License-Identifier: Unlicensed


import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "./05_11_Strings.sol";
import "./04_11_draft-EIP712.sol";
import "./03_11_ECDSA.sol";
import 'erc721a/contracts/ERC721A.sol';


pragma solidity 0.8.7;

contract WagmiFootball is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

// ================== Variables Start =======================
 

  // call type hash
  //bytes32 constant public MINT_CALL_HASH_TYPE = keccak256("claim(address _rec,uint256 num,uint256 _price)");

  // contract signer address
  //address public cSigner=0x898C148439e6E1F53EC4565662841b1B62AF8687; 


  
  // reveal uri - p.s set it in contructor (if sniper proof, else put some dummy text and set the actual revealed uri just before reveal)
  string public uri="https://fusible.mypinata.cloud/ipfs/QmXfiUQJAAWqzencjqfUGdJ2kUztfyzcdN1guD7fTQjtbE";


  // prices - replace it with yours

  uint256 public switchPrice = 0.0001 ether;

  uint256 public FIFA_END_TIME;// Declare Win
  uint256 public MINT_OVER;
  //uint256 public genXprice = 0.001 ether;

  // supply - replace it with yours
  uint256 public supplyLimit = 2000;
  //uint256 public freeMintSupplyLimit=22;
  //uint256 private freeCount;
  // max per tx - replace it with yours
  uint256 public maxMintAmountPerTx = 20;//5x20 => 100 NFT
  //uint256 public wlmaxMintAmountPerTx = 2;
  //uint256 public genXmaxMintAmountPerTx = 1;

  // max per wallet - replace it with yours
  uint256 public maxLimitPerWallet = 20;
  //uint256 public wlmaxLimitPerWallet = 2;
  uint256 public winner = 69;//0-31 
  uint256 public winningAmount=0;

  // enabled
  //bool public whitelistSale = false;
  bool public publicSale = false;

 
   mapping (uint256 => uint256) public totalTeamMints;
   mapping (uint256 =>bool) public claimed;
   
  string[16] public TEAM = ["ARG","AUS","BRA","CRO","ENG","FRA","JPN","KOR","MOR","NED","POL","POR","SEN","SPA","SWI","USA"];

  mapping(uint256=> uint256) public bin;


// ================== Variables End =======================  
// ================== Modifier ============================
    modifier isFIFAMintOver() {
        require(block.timestamp < MINT_OVER, "Mint is Over");
        _;
    }
// ================== Constructor Start =======================

  // Token NAME and SYMBOL - Replace it with yours
  constructor(
    //string memory _uri
   uint256 end,uint256 mint_end
  ) ERC721A("WAGMI.FOOTBALL FIFA 2022 x WAGMI11", "WFxW11")  {
   // seturi(_uri);
    MINT_OVER=mint_end;
    FIFA_END_TIME=end;
  }

// ================== Constructor End =======================

// ================== Mint Functions Start =======================


  event Minted( address by, uint team, uint qty);
  function PublicMint(uint256 _mintQty,uint256 _t) nonReentrant() isFIFAMintOver() public  {
    
    // Normal requirements 
    require(publicSale && _t<16, 'The PublicSale is paused!');
    require(_mintQty > 0 && _mintQty <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintQty <= supplyLimit, 'Max supply exceeded!');
    require(balanceOf(msg.sender) + _mintQty <= maxLimitPerWallet, 'Max mint per wallet exceeded!');
   // Mint
     _safeMintTeam(_msgSender(), _mintQty,_t);
     emit Minted(msg.sender,_t,_mintQty);
  }

  function switchTeam (uint256[] memory _tokenIds,uint256 _team)  isFIFAMintOver() external payable {
    uint256 l = _tokenIds.length;
    require(l<=5,"Array too big to compute");
    uint256 v=l*switchPrice;
    uint256 i;
    for(i;i<l;i++){
    uint256 t_id = _tokenIds[i];
    uint256 o_t = bin[t_id];
    require(ownerOf(t_id)==msg.sender,"You don't own this NFT!");
    require(_team<16 && _team != o_t,"Invalid Team selected");
    require(msg.value >= v ,"Inavlid payable amt");
    assignTeam(_team,t_id);
    totalTeamMints[o_t] = totalTeamMints[o_t]-1;
   
    }
   
  }

  function Airdrop(uint256 _t,uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= supplyLimit, 'Max supply exceeded!');

    //assignTeam( _team, _tokenId);
    _safeMintTeam(_receiver, _mintAmount,_t);
  }

// ================== Mint Functions End =======================  
event Claimed(address, uint);
 function claimReward(uint256[] memory _tokenIds) nonReentrant external {
    uint256 l = _tokenIds.length;
    uint256 tReward;
    require(block.timestamp>FIFA_END_TIME,"Come back when FIFA is over");
    for(uint256 i;i<l;i++ ){
    uint256 t_id = _tokenIds[i];
    require(ownerOf(t_id)==msg.sender,"You don't own this NFT!");
    require(bin[t_id]==winner,"Not the winner");
    require(!claimed[_tokenIds[i]],"Already Claimed");
    tReward=tReward+winningAmount;
    claimed[_tokenIds[i]]=true;
    }
    require(tReward<=address(this).balance,"Insufficient Balance in the pool");
    _withdraw(msg.sender,tReward);
    emit Claimed(msg.sender,tReward);
  }

// ================== Set Functions Start =======================

// uri
  function seturi(string memory _uri) public onlyOwner {
    uri = _uri;
  }

// set Contract Signer
  // function setCSigner(address _signer) public onlyOwner{
  //     cSigner=_signer;
  // }

// sales toggle
  function setpublicSale(bool _publicSale) public onlyOwner {
    publicSale = _publicSale;
  }


// max per tx
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }


// max per wallet
  function setmaxLimitPerWallet(uint256 _maxLimitPerWallet) public onlyOwner {
    maxLimitPerWallet = _maxLimitPerWallet;
  }

  function extendDuration(uint8 _type, uint256 _d) public onlyOwner{
    if(_type ==0)
     FIFA_END_TIME = block.timestamp+_d;
    else
     MINT_OVER =block.timestamp+_d;
  }


// supply limit
  function setsupplyLimit(uint256 _supplyLimit) public onlyOwner {
    supplyLimit = _supplyLimit;
  }
  function setWinner(uint256 _w,uint256 _a) public onlyOwner{
    winner=_w;
    uint256 w_t = totalTeamMints[_w];
    _a=_a*1000;
    winningAmount = _a/w_t;
    winningAmount=winningAmount/1000;
  }

  
// ================== Set Functions End =======================

// ================== Withdraw Function Start =======================
  
  function withdraw() public onlyOwner nonReentrant {
    //owner withdraw 
      _withdraw(owner(),address(this).balance);
  }

  function _withdraw(address to,uint256 _v) internal {
    (bool os, ) = payable(to).call{value: _v}('');
    require(os);
  }

 

// ================== Withdraw Function End=======================  

// ================== Read Functions Start =======================

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= supplyLimit) {
      TokenOwnership memory ownership = _ownershipAt(currentTokenId);

      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }

      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }


  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    // if (revealed == false) {
    //   return hiddenMetadataUri;
    // }

    // string memory currentBaseURI = _baseURI();
    // return bytes(currentBaseURI).length > 0
    //     ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
    //     : '';
    //    string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "TEST Bag #', toString(_tokenId), '", "description": "TEST Collection is collection of  health care institutes and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use BMWC in any way you want.", "image": "', _baseURI(), '","attributes":[{"trait_name":"UUID","value":"',bin[_tokenId].uuid,'"},{"trait_name":"bin","value":"',bin[_tokenId]._type,'"},{"trait_name":"weight","value":"',toString(bin[_tokenId].weight),'"},{"trait_name":"status","value":"',getStatus(_tokenId),'"}]}'))));
    string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "WFxW11 ',TEAM[bin[_tokenId]],'#',toString(_tokenId),'","description": "Wamgi.Football by Wagmi11 Collection is an innovative approach to bring sports fans & web3 together with NFT Raffles and Prediction marketplace.","image": "', _baseURI(),'/', TEAM[bin[_tokenId]],'.png","attributes":[{"trait_type":"Team","value":"',TEAM[bin[_tokenId]],'"},{"trait_type":"Claim Status","value":"',getClaimStatus(_tokenId),'"},{"trait_type":"Status","value":"',getStatus(bin[_tokenId]),'"}]}'))));
  
        string memory output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
  }

  function getStatus(uint256 tokenId) public view returns(string memory){
        if(block.timestamp < FIFA_END_TIME) return "In Progress";
        if(winner == tokenId) return "Winner";
        else if(winner == 69) return "Updating Soon";
        else return "Eliminated";
    }
  function getClaimStatus(uint256 tokenId) public view returns(string memory){
    if(bin[tokenId]==winner){
    if (claimed[tokenId]) return "Claimed";
    else return "UnClaimed";
    }
    return "N/A";
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }


  function totalMinted() public view returns(uint256){
    return _totalMinted();
  }

  function ownershipAt(uint256 tokenId) public view  returns (TokenOwnership memory) {
        return _ownershipAt(tokenId);
    }
  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
  //assign Team to tokenId.
  function assignTeam(uint256 _team, uint256 _tokenId) internal virtual {
    totalTeamMints[_team] = totalTeamMints[_team]+1;
    bin[_tokenId]= _team; 
  }
// ================== Read Functions End =======================  
//================Override========================

    function _safeMintTeam(address to, uint256 quantity,uint256 team)  internal virtual   {
                _mint(to, quantity);
      uint256 _currentIndex = _nextTokenId();
        unchecked {
        
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    // if (!this._checkContractOnERC721Received(address(0), to, index++, _data)) {
                    //     revert TransferToNonERC721ReceiverImplementer();
                    // }
                    assignTeam(team,index++);
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            
        }
    }

// Receive ETH
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

}


library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}