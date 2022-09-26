// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";



interface FreeCity{
function preMint(address to, uint256 quality) external;
}

contract VoiceBenefitCard is OwnableUpgradeable,ERC1155Upgradeable{

    using ECDSAUpgradeable for bytes32;
    address private openSea;

    mapping(address=>uint256)  public ownTokenId;

    address private freeCity;
    
    mapping(address => uint256) public mintTotal;

    mapping(uint256=>string) tokenMapUri;

    mapping(uint256=>uint256) private arrRandom;

    mapping(uint256=>uint256) private mintPrice;

    uint256 public totalSupply;

    uint256 public flag;

    uint256 private index;

    event PreMint(address,uint256);

    function init(uint256 _totalSupply,uint256[6] memory mintPrices) public  initializer  {
                 __Ownable_init();
           tokenMapUri[1]="https://vio.infura-ipfs.io/ipfs/Qmf1JQ9yN71haWAmg3Abyz2emD3Dpp7ZEwL9eTqzoJq26A/N.png";
           tokenMapUri[2]="https://vio.infura-ipfs.io/ipfs/Qmf1JQ9yN71haWAmg3Abyz2emD3Dpp7ZEwL9eTqzoJq26A/R.png";
           tokenMapUri[3]="https://vio.infura-ipfs.io/ipfs/Qmf1JQ9yN71haWAmg3Abyz2emD3Dpp7ZEwL9eTqzoJq26A/SR.png";
           tokenMapUri[4]="https://vio.infura-ipfs.io/ipfs/Qmf1JQ9yN71haWAmg3Abyz2emD3Dpp7ZEwL9eTqzoJq26A/SSR.png";
           tokenMapUri[5]="https://vio.infura-ipfs.io/ipfs/Qmf1JQ9yN71haWAmg3Abyz2emD3Dpp7ZEwL9eTqzoJq26A/UR.png";
           totalSupply   = _totalSupply;
           setEveryNftMintPrice(mintPrices);
    }

    function airdrop(address to, uint256 id,bytes32 _hash,uint8 v,bytes32 r,bytes32 s)public {
        require(keccak256(abi.encode(to,id))==_hash,"n1");
        require(ecrecover(_hash, v, r, s)==owner(),"n2");
        require(id > 0 && id < 6,"n3");
        require(ownTokenId[to]==0,"n4");
         _mint(to, id, 1, "");
         ownTokenId[to]=id;
    }

    function isApprovedToMint(bytes32 _hash, bytes memory signature) internal view returns (bool) {
       (address recovered, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(_hash, signature);
        return error == ECDSAUpgradeable.RecoverError.NoError && recovered == owner();
    }

    function mint(
        address to,
        uint256 id
    ) public  onlyOwner() {
             require(id > 0 && id < 6,"id error");
             require(ownTokenId[to]==0,"only an card");
             _mint(to, id, 1, "");
              ownTokenId[to]=id;
    }

    function tokenURI(uint256 id) public view  returns(string memory){
        return tokenMapUri[id];
    }

    function setFreeCityContract(address _freeCity) public onlyOwner(){ 
       freeCity = _freeCity;
    }

    function getFreeCityContract() view external returns(address) {
      return freeCity;
    }

    function setEveryNftMintPrice(uint256[6] memory mintPrices) public onlyOwner(){
        for (uint256 i = 0; i < mintPrices.length; i++) {
            mintPrice[i] = mintPrices[i];
        }
    }

    function setSingleNftMintPrice(uint256 id,uint256 mintSinglePrice) external onlyOwner(){
        require(id > 0 && id < 6,"id error");
        mintPrice[id] = mintSinglePrice;
    }

    function  getMintPrice(address account) public view returns(uint256){
        uint quality = ownTokenId[account];
        return mintPrice[quality];
    }



    function setTotalSupply(uint256 _totalSupply) external onlyOwner(){
        totalSupply = _totalSupply;
    }


    function pushArr(uint[] memory arr) external onlyOwner(){
        uint256 _index = flag;
        for(uint256 i = 0;i < arr.length; i++){
            arrRandom[_index + i] = arr[i];
        }
        flag = flag + arr.length;
    }


    function getArr(uint _index) public view returns(uint256){
        return arrRandom[_index];
    }



    function preSale( uint numberOfTokens,uint[] memory qualityCategory) external payable{
      require(index <= totalSupply,"Exceeding the total amount");
      require(numberOfTokens == qualityCategory.length,"length mismatch");
      require(msg.value >= (getMintPrice(msg.sender) * numberOfTokens)," value error");
      require(mintTotal[msg.sender] + numberOfTokens <= uint8(5),"Exceeded times");

       for (uint256 i = 0; i < numberOfTokens; i++) {
            FreeCity(freeCity).preMint(msg.sender,qualityCategory[i]);
        }
        index = index + numberOfTokens;
        mintTotal[msg.sender] = mintTotal[msg.sender] + numberOfTokens;

       emit PreMint(msg.sender,numberOfTokens);
    }
    
    function withDraw(address to) public onlyOwner(){
        payable(to).transfer(address(this).balance);
    }


    function setOpenSea(address _openSea)
        external
        onlyOwner()
    {
        openSea = _openSea;
    }

    function getOpenSea() public view returns (address) {
        return openSea;
    }

    /**
     * Override isApprovedForAll to auto-approve OS's proxy contract
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override(ERC1155Upgradeable)
        returns (bool isOperator)
    {
        // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        // for Polygon's Mumbai testnet, use 0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c
        if (openSea != address(0) && _operator == openSea) {
            return true;
        }
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC1155Upgradeable.isApprovedForAll(_owner, _operator);
    }

}