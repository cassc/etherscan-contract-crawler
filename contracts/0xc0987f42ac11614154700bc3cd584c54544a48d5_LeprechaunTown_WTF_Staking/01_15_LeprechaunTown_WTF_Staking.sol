// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/*
     .-. .-.
    (   |   )
  .-.:  |  ;,-.
 (_ __`.|.'_ __)
 (    ./Y\.    )
  `-.-' | `-.-'
        \ 🌈 ☘️ + ⌛ = 💰
*/

contract LeprechaunTown_WTF_Staking is ERC20, ERC721Holder, ERC1155Holder, Ownable{
    address public projectLeader; // Project Leader Address
    address[] public admins; // List of approved Admins

    IERC721 public parentNFT_A; //main 721 NFT contract
    IERC1155 public parentNFT_B; //main 1155 NFT contract

    mapping(uint256 => address) public tokenOwnerOf_A;
    mapping(uint256 => uint256) public tokenStakedAt_A;

    mapping(uint256 => address) public tokenOwnerOf_B;
    mapping(uint256 => uint256) public tokenStakedAt_B;

    bool public pausedStake_A = true;
    bool public pausedStake_B = true;

    uint256 public limitPerSession = 10;

    uint256 public EMISSION_RATE = (1 * 10 ** decimals()) / 1 days; //rate of max 1 tokens per day(86400 seconds) 
    //math for emission rate: EMISSION_RATE * 86400 = token(s) per day
    //uint256 private initialSupply = (10000 * 10 ** decimals()); //( 10000 )starting amount to mint to treasury in WEI

    constructor(address _parentNFT_A, address _parentNFT_B) ERC20("$GOLD", "$GOLD") {
        parentNFT_A = IERC721(_parentNFT_A); // on deploy this is the main NFT contract (parentNFT_A)
        parentNFT_B = IERC1155(_parentNFT_B); // on deploy this is the main NFT contract (parentNFT_B)
        //_mint(msg.sender, initialSupply);
    }

    /**
     * @dev The contract developer's website.
     */
    function contractDev() public pure returns(string memory){
        string memory dev = unicode"🐸 HalfSuperShop.com 🐸";
        return dev;
    }

    /**
     * @dev Admin can set the limit of IDs per session.
     */
    function setLimitPerSession(uint256 _limit) external onlyAdmins {
        limitPerSession = _limit;
    }

    /**
     * @dev Admin can set the EMISSION_RATE.
     */
    function setEmissionRate(uint256 _RatePerDay) external onlyAdmins {
        EMISSION_RATE = (_RatePerDay * 10 ** decimals()) / 1 days;
    }

    /**
     * @dev Admin can set the PAUSE state for contract A or B.
     * true = no staking allowed
     * false = staking allowed
     */
    function pauseStaking(bool _contract_A, bool _state) public onlyAdmins {
        if(_contract_A){
            pausedStake_A = _state;
        }
        else{
            pausedStake_B = _state;
        }
    }

    /**
     * @dev User can stake NFTs they own to earn rewards over time.
     * Note: User must set this contract as approval for all on the parentNFT contracts in order to stake NFTs.
     * This function only stakes NFT IDs from the parentNFT_A or parentNFT_B contract.
     */
    function stake(uint[] memory _tokenIDs, bool _contract_A) public {
        require(_tokenIDs.length != 0, "No IDs");
        require(_tokenIDs.length <= limitPerSession, "Too Many IDs");
        if(_tokenIDs.length == 1){
            stakeOne(_tokenIDs[0], _contract_A);
        }
        else{
            stakeMultiple(_tokenIDs, _contract_A);
        }
    }

    function stakeOne(uint256 _tokenID, bool _contract_A) private {
        if(_contract_A){
            require(pausedStake_A != true, "Contract A Staking Paused");
            require(tokenOwnerOf_A[_tokenID] == 0x0000000000000000000000000000000000000000, "NFT ALREADY STAKED");
            parentNFT_A.safeTransferFrom(msg.sender, address(this), _tokenID);
            tokenOwnerOf_A[_tokenID] = msg.sender;
            tokenStakedAt_A[_tokenID] = block.timestamp;
        }
        else{
            require(pausedStake_B != true, "Contract B Staking Paused");
            require(tokenOwnerOf_B[_tokenID] == 0x0000000000000000000000000000000000000000, "NFT ALREADY STAKED");
            parentNFT_B.safeTransferFrom(msg.sender, address(this), _tokenID, 1, "0x00");
            tokenOwnerOf_B[_tokenID] = msg.sender;
            tokenStakedAt_B[_tokenID] = block.timestamp;
        }
    }

    function stakeMultiple(uint[] memory _tokenIDs, bool _contract_A) private {
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uint256 _tokenID = _tokenIDs[i];
            stakeOne(_tokenID, _contract_A);
        }
    }

    /**
     * @dev User can check estimated rewards gained so far from an address that staked an NFT.
     * Note: The staker address must have an NFT currently staked.
     * The returned amount is calculated as Wei. 
     * Use https://etherscan.io/unitconverter for conversions or do math returnedValue / (10^18) = reward estimate.
     */
    function estimateRewards(uint[] memory _tokenIDs, bool _contract_A) public view returns (uint256) {
        uint256 timeElapsed;
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uint256 _tokenID = _tokenIDs[i];
            if(_contract_A){
                require(tokenOwnerOf_A[_tokenID] != 0x0000000000000000000000000000000000000000, "NFT NOT STAKED");
                //rewards can be set within this function based on the amount and time NFTs are staked
                timeElapsed += (block.timestamp - tokenStakedAt_A[_tokenID]);
            }
            else{
                require(tokenOwnerOf_B[_tokenID] != 0x0000000000000000000000000000000000000000, "NFT NOT STAKED");
                //rewards can be set within this function based on the amount and time NFTs are staked
                timeElapsed += (block.timestamp - tokenStakedAt_B[_tokenID]);
            }
        }

        return timeElapsed * EMISSION_RATE;
    } 

    /**
     * @dev User can unstake NFTs to earn the rewards gained over time.
     * Note: User must have a NFT already staked in order to unstake and gain rewards.
     * This function only unstakes NFT IDs that they currently have staked.
     * Rewards are calculated based on the Emission_Rate.
     */
    function unstake(uint[] memory _tokenIDs, bool _contract_A) public {
        require(_tokenIDs.length != 0, "No IDs");
        require(_tokenIDs.length <= limitPerSession, "Too Many IDs");
        require(isOwnerOfAllStaked(msg.sender, _contract_A, _tokenIDs), "CANNOT UNSTAKE");

        uint256 reward = estimateRewards(_tokenIDs, _contract_A);

        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uint256 _tokenID = _tokenIDs[i];
            if(_contract_A){
                parentNFT_A.safeTransferFrom(address(this), msg.sender, _tokenID);
                delete tokenOwnerOf_A[_tokenID];
                delete tokenStakedAt_A[_tokenID];
            }
            else{
                parentNFT_B.safeTransferFrom(address(this), msg.sender, _tokenID, 1, "0x00");
                delete tokenOwnerOf_B[_tokenID];
                delete tokenStakedAt_B[_tokenID];
            }
        }
        _mint(msg.sender, reward); // Minting the reward tokens gained for staking
    }

    /**
     * @dev Allows Owner or Project Leader to set the parentNFT contracts to a specified address.
     * WARNING: Please ensure all users NFTs are unstaked before setting a new address
     */
    function setStakingContract(bool _contract_A, address _contractAddress) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "Owner or Project Leader Only: caller is not Owner or Project Leader");

        if(_contract_A){
            parentNFT_A = IERC721(_contractAddress); // set the main NFT contract (parentNFT_A)
        }
        else{
            parentNFT_B = IERC1155(_contractAddress); // set the main NFT contract (parentNFT_B)
        }
    }

    /**
     * @dev Returns the owner address of a specific token staked
     * Note: If address returned is 0x0000000000000000000000000000000000000000 token is not staked.
     */
    function getTokenOwnerOf(bool _contract_A, uint256 _tokenID) public view returns(address){
        if(_contract_A){
            return tokenOwnerOf_A[_tokenID];
        }
        else{
            return tokenOwnerOf_B[_tokenID];
        }
    }

    function isOwnerOfAllStaked(address _holder, bool _contract_A, uint[] memory _tokenIDs) public view returns(bool){
        for (uint256 i = 0; i < _tokenIDs.length; i++) {
            uint256 _tokenID = _tokenIDs[i];

            if(getTokenOwnerOf(_contract_A, _tokenID) == _holder){
                //HOLDER IS TRUE
            }
            else{
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Returns the unix date the token was staked
     */
    function getStakedAt(bool _contract_A, uint256 _tokenID) public view returns(uint256){
        if(_contract_A){
            return tokenStakedAt_A[_tokenID];
        }
        else{
            return tokenStakedAt_B[_tokenID];
        }
    }

    /**
     * @dev Allows Admins to mint an amount of tokens to a specified address.
     * Note: _amount must be in WEI use https://etherscan.io/unitconverter for conversions.
     */
    function mintTokens(address _to, uint256 _amount) external onlyAdmins {
        _mint(_to, _amount); // Minting Tokens
    }

     /**
     * @dev Throws if called by any account other than the owner or admin.
     */
    modifier onlyAdmins() {
        _checkAdmins();
        _;
    }

    /**
     * @dev Throws if the sender is not the owner or admin.
     */
    function _checkAdmins() internal view virtual {
        require(checkIfAdmin(), "Admin Only: caller is not an admin");
    }

    function checkIfAdmin() public view returns(bool) {
        if (msg.sender == owner() || msg.sender == projectLeader){
            return true;
        }
        if(admins.length > 0){
            for (uint256 i = 0; i < admins.length; i++) {
                if(msg.sender == admins[i]){
                    return true;
                }
            }
        }
        
        // Not an Admin
        return false;
    }

    /**
     * @dev Owner and Project Leader can set the addresses as approved Admins.
     * Example: ["0xADDRESS1", "0xADDRESS2", "0xADDRESS3"]
     */
    function setAdmins(address[] calldata _users) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "Owner or Project Leader Only: caller is not Owner or Project Leader");
        delete admins;
        admins = _users;
    }

    /**
     * @dev Owner or Project Leader can set the address as new Project Leader.
     */
    function setProjectLeader(address _user) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "Owner or Project Leader Only: caller is not Owner or Project Leader");
        projectLeader = _user;
    }

}