/**
 *Submitted for verification at Etherscan.io on 2023-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721{
    function balanceOf(address owner) external view returns (uint256 balance);    
    function transferFrom(address from, address to, uint256 tokenId) external;
    function tokenOfOwnerByIndex(address owner, uint256 index) external  view  returns (uint256);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract GameStakingDual{
    address SanshiNFT = 0x6976Af8b25C97A090769Fa97ca9359c891353f61;
    address DogsNFT = 0x645AD1A9E71F0c2Ea18b6184A894eD0C8b093377;
    address owner;
    bool public unstake_enable;
    mapping(address => uint256) public _balances;
    mapping(address => mapping(uint256 => uint256)) public _tokensOfOwners; // address of Owner => (number in stacking => NFT ids)
    mapping(address => mapping(uint256 => uint256)) public _tokensOfOwnersDogs;
    mapping(uint256 => address) public _holders;     
    mapping(address => bool)    public _isHolder;
    uint256 public _totalHolders;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function tokensOfOwner_NFT(address _owner, uint256 _start, uint256 _end) external view returns(uint256[] memory) {
        uint256[] memory tokensId = new uint256[](_end - _start);
        for(uint i = _start; i < _end; i++){
            tokensId[i] = IERC721(SanshiNFT).tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function getHolders(uint256 _start, uint256 _end) public view returns (address[] memory, uint256[] memory) {
        address[] memory holders = new address[](_end - _start);
        uint256[] memory balances = new uint256[](_end - _start);
        uint256 j = 0;
        for (uint256 i = _start; i < _end; i++) {           
            holders[j]   = _holders[i];
            balances[j]  = _balances[_holders[i]];
            j++;
        }
        return (holders, balances);
    }


    function depositNft(uint256[] memory tokenIds, uint256[] memory tokenIdsDogs) public {
        address Staker = msg.sender;
        require(IERC721(SanshiNFT).isApprovedForAll(Staker, address(this)), ": SanshiNFT token consumption not allowed");
        require(IERC721(DogsNFT).isApprovedForAll(Staker, address(this)), ": DogsNFT token consumption not allowed");
        for(uint i = 0; i < tokenIds.length; i++){
            IERC721(SanshiNFT).transferFrom(Staker, address(this), tokenIds[i]); //transfer the token with the specified id to the balance of the staking contract
            IERC721(DogsNFT).transferFrom(Staker, address(this), tokenIdsDogs[i]);
            _balances[Staker]++; //increase staker balance
            uint256 Staker_balance = _balances[Staker];            
            _tokensOfOwners[Staker][Staker_balance] = tokenIds[i]; // We remember the token id on the stack in order          
            _tokensOfOwnersDogs[Staker][Staker_balance] = tokenIdsDogs[i];   
        }

        if(_isHolder[msg.sender] == false){
            _holders[_totalHolders] = msg.sender;
            _isHolder[msg.sender] = true;
            _totalHolders++;
        }
    }

    function unstakeNft(uint256 _count) public {
        address Staker = msg.sender;
        require(_balances[Staker] > 0, ": No tokens in staking");
        require(unstake_enable == true, ": Unstaking not enable");
        for(uint i = 0; i < _count; i++){           
            uint256 Staker_balance = _balances[Staker];

            uint256 tokenId = _tokensOfOwners[Staker][Staker_balance];
            IERC721(SanshiNFT).transferFrom(address(this), Staker, tokenId); //transfer the token 

            uint256 tokenIdDogs = _tokensOfOwnersDogs[Staker][Staker_balance];
            IERC721(DogsNFT).transferFrom(address(this), Staker, tokenIdDogs); //transfer the token 
            _balances[Staker]--; //decrease staker balance
        }
    }

    function set_SanshiNFT(address _SanshiNFT, address _DogsNFT) external onlyOwner {
        SanshiNFT = _SanshiNFT;
        DogsNFT = _DogsNFT;
    }

    function flip_unstake_enable() external onlyOwner {
        unstake_enable = !unstake_enable;
    }
}