// SPDX-License-Identifier: MIT
/*
              ████      ████
            ██████      ██████ 
          ████████      ████████
          ██████████████████████  
          ██████████████████████ 
          ██████  ██████  ██████ 
          ██████  ██  ██  ██████   
        ██████████████████████████
      ██████████          ██████████
          ████████      ████████
            ██████████████████
                ██████████

               Wulfz / 2021
*/
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./Profile.sol";
import "./Awoo.sol";
import "./StakingPool.sol";

contract WulfzNFT is Profile, Ownable {
    enum WulfzType {
        Genesis,
        Pupz,
        Alpha
    }

    struct WulfzInfo {
        WulfzType wType;
        bool bStaked;
        uint256 lastBreedTime;
    }

    event WulfzMinted(
        address indexed user,
        uint256 indexed tokenId,
        uint256 indexed wType
    );

    event PreSaleTimeChanged(uint256 newTime, uint256 currentTime);
    event PublicSaleTimeChanged(uint256 newTime, uint256 currentTime);
    event StakingTimeChanged(uint256 newTime, uint256 currentTime);
    event EvolveTimeChanged(uint256 newTime, uint256 currentTime);
    event AdoptionTimeChanged(uint256 newTime, uint256 currentTime);
    event PoolAddrSet(address from, address addr);
    event UtilityAddrSet(address from, address addr);

    uint256 public constant MINT_PRICE = 80000000000000000; // 0.08 ETH
    uint256 public constant BREED_PRICE = 600;
    uint256 public constant EVOLVE_PRICE = 1500;
    uint256[] private COOLDOWN_TIME_FOR_BREED = [14 days, 0, 7 days];

    uint256[] private MAX_SUPPLY_BY_TYPE = [5555, 10000, 100];
    uint256[] private START_ID_BY_TYPE = [0, 6000, 5600];
    uint256[] public totalSupplyByType = [0, 0, 0];

    uint256 public startTimeOfPrivateSale;
    uint256 public startTimeOfPublicSale;
    uint256 public startTimeOfStaking;
    uint256 public startTimeOfAdopt;
    uint256 public startTimeOfEvolve;

    mapping(uint256 => WulfzInfo) public wulfz;

    mapping(address => bool) private claimInPresale;
    mapping(address => uint256) private claimInPublicSale;

    string public _baseTokenURI =
        "https://ipfs.io/ipfs/QmQtN81i9eNrD3wxcr67scDpLvZDDXxbmAvNXMaZh3D6tB/";

    UtilityToken private _utilityToken;
    StakingPool private _pool;

    constructor(string memory _name, string memory _symbol)
        Profile(_name, _symbol)
    {
        startTimeOfPrivateSale = 1640624400; // Mon Dec 27 2021 12:00:00 GMT-0500 (Eastern Standard Time)
        startTimeOfPublicSale = 1640710800; // Tue Dec 28 2021 12:00:00 GMT-0500 (Eastern Standard Time)
        startTimeOfStaking = 1641574800; // Fri Jan 07 2022 12:00:00 GMT-0500 (Eastern Standard Time)
        startTimeOfAdopt = 1646110800; // Tue Mar 01 2022 00:00:00 GMT-0500 (Eastern Standard Time)
        startTimeOfEvolve = 1654056000; // Wed Jun 01 2022 00:00:00 GMT-0400 (Eastern Daylight Time)

        // 55 Wulfz will be held in the Vault for Promotional purposes
        for (uint256 i = 0; i < 55; i++) {
            mintOne(WulfzType.Genesis);
        }
    }

    /**
     * @dev return the Base URI of the token
     */

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev set the _baseTokenURI
     * @param _newURI of the _baseTokenURI
     */

    function setBaseURI(string calldata _newURI) external onlyOwner {
        _baseTokenURI = _newURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance is zero");
        payable(msg.sender).transfer(balance);
    }

    function getWulfzType(uint256 _tokenId) public view returns (uint256) {
        return uint256(wulfz[_tokenId].wType);
    }

    /**
     * @dev Only whitelisted can mint
     */
    function Presale(bytes32[] calldata _proof) external payable {
        require(msg.value >= MINT_PRICE, "Minting Price is not enough");
        require(
            block.timestamp > startTimeOfPrivateSale,
            "Private Sale is not started yet"
        );
        require(
            block.timestamp < startTimeOfPrivateSale + 86400,
            "Private Sale is already ended"
        );

        require(
            !claimInPresale[msg.sender],
            "You've already minted token. If you want more, you will be able to mint during Public Sale"
        );

        bytes32 merkleTreeRoot = 0x12b1013fe853dea282b3440a70e5d739b7ef75e135122659fe5408bde23a4cc1;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_proof, merkleTreeRoot, leaf),
            "Sorry, you're not whitelisted. Please try Public Sale"
        );

        claimInPresale[msg.sender] = true;
        mintOne(WulfzType.Genesis);
    }

    /**
     * @dev Mint the _amount of tokens
     * @param _amount is the token count
     */
    function PublicSale(uint256 _amount) external payable {
        require(
            msg.value >= MINT_PRICE * _amount,
            "Minting Price is not enough"
        );
        require(
            block.timestamp > startTimeOfPublicSale,
            "Public Sale is not started yet"
        );
        require(
            block.timestamp < startTimeOfPublicSale + 86400,
            "Public Sale is already ended"
        );
        require(_amount < 3, "You can only require at most 2");
        require(
            claimInPublicSale[msg.sender] < 3,
            "You can only mint at most 2 during Public Sale"
        );

        claimInPublicSale[msg.sender] += _amount;
        for (uint256 i = 0; i < _amount; i++) {
            mintOne(WulfzType.Genesis);
        }
    }

    function mintOne(WulfzType _type) private {
        require(msg.sender == tx.origin);
        require(
            totalSupplyByType[uint256(_type)] <
                MAX_SUPPLY_BY_TYPE[uint256(_type)],
            "All tokens are minted"
        );

        uint256 tokenId = ++totalSupplyByType[uint256(_type)];
        tokenId += START_ID_BY_TYPE[uint256(_type)];
        _safeMint(msg.sender, tokenId);
        wulfz[tokenId].wType = _type;

        emit WulfzMinted(msg.sender, tokenId, uint256(_type));
    }

    function setUtilitytoken(address _addr) external onlyOwner {
        _utilityToken = UtilityToken(_addr);
        emit UtilityAddrSet(address(this), _addr);
    }

    function setStakingPool(address _addr) external onlyOwner {
        _pool = StakingPool(_addr);
        emit PoolAddrSet(address(this), _addr);
    }

    function setStartTimeOfPrivateSale(uint256 _timeStamp) external onlyOwner {
        startTimeOfPrivateSale = _timeStamp;
        emit PreSaleTimeChanged(startTimeOfPrivateSale, block.timestamp);
    }

    function setStartTimeOfPublicSale(uint256 _timeStamp) external onlyOwner {
        startTimeOfPublicSale = _timeStamp;
        emit PublicSaleTimeChanged(startTimeOfPublicSale, block.timestamp);
    }

    /*******************************************************************************
     ***                            Staking Logic                                 ***
     ******************************************************************************** */
    function setStakingTime(uint256 _timeStamp) external onlyOwner {
        startTimeOfStaking = _timeStamp;
        emit StakingTimeChanged(startTimeOfStaking, block.timestamp);
    }

    function startStaking(uint256 _tokenId) external {
        require(
            block.timestamp > startTimeOfStaking,
            "Staking Mechanism is not started yet"
        );
        require(ownerOf(_tokenId) == msg.sender, "Staking: owner not matched");
        require(
            !wulfz[_tokenId].bStaked,
            "This Token is already staked. Please try another token."
        );

        _pool.startStaking(msg.sender, _tokenId);
        _safeTransfer(msg.sender, address(_pool), _tokenId, "");
        wulfz[_tokenId].bStaked = true;
    }

    function stopStaking(uint256 _tokenId) external {
        require(
            wulfz[_tokenId].bStaked,
            "This token hasn't ever been staked yet."
        );
        _pool.stopStaking(msg.sender, _tokenId);
        _safeTransfer(address(_pool), msg.sender, _tokenId, "");
        wulfz[_tokenId].bStaked = false;
    }

    /*******************************************************************************
     ***                            Adopting Logic                               ***
     ********************************************************************************/
    function setAdoptTime(uint256 _timeStamp) external onlyOwner {
        startTimeOfAdopt = _timeStamp;
        emit AdoptionTimeChanged(startTimeOfAdopt, block.timestamp);
    }

    function canAdopt(uint256 _tokenId) public view returns (bool) {
        uint256 wType = uint256(wulfz[_tokenId].wType);

        require(
            wulfz[_tokenId].wType != WulfzType.Pupz,
            "Try adopting with Genesis or Alpha Wulfz"
        );

        uint256 lastBreedTime = wulfz[_tokenId].lastBreedTime;
        uint256 cooldown = COOLDOWN_TIME_FOR_BREED[wType];

        return (block.timestamp - lastBreedTime) > cooldown;
    }

    function isAdoptionStart() public view returns (bool) {
        return block.timestamp > startTimeOfAdopt;
    }

    function adopt(uint256 _parent) external {
        require(
            canAdopt(_parent),
            "Already adopt in the past days. Genesis Wulfz can adopt every 14 days and Alpha can do every 7 days."
        );
        require(isAdoptionStart(), "Adopting Pupz is not ready yet");
        require(
            ownerOf(_parent) == msg.sender,
            "Adopting: You're not owner of this token"
        );
        require(
            !wulfz[_parent].bStaked,
            "This Token is already staked. Please try another token."
        );

        _utilityToken.burn(
            msg.sender,
            BREED_PRICE * (10**_utilityToken.decimals())
        );

        mintOne(WulfzType.Pupz);
        wulfz[_parent].lastBreedTime = block.timestamp;
    }

    /*******************************************************************************
     ***                            Evolution Logic                              ***
     ********************************************************************************/
    function setEvolveTime(uint256 _timeStamp) external onlyOwner {
        startTimeOfEvolve = _timeStamp;
        emit EvolveTimeChanged(startTimeOfEvolve, block.timestamp);
    }

    function isEvolveStart() public view returns (bool) {
        return block.timestamp > startTimeOfEvolve;
    }

    function evolve(uint256 _tokenId) external {
        require(isEvolveStart(), "Evolving Wulfz is not ready yet");
        require(
            ownerOf(_tokenId) == msg.sender,
            "Evolve: You're not owner of this token"
        );
        require(
            wulfz[_tokenId].wType == WulfzType.Genesis,
            "Genesis can only evolve Alpha"
        );
        require(
            !wulfz[_tokenId].bStaked,
            "This Token is already staked. Please try another token."
        );

        _utilityToken.burn(
            msg.sender,
            EVOLVE_PRICE * (10**_utilityToken.decimals())
        );

        _burn(_tokenId);
        mintOne(WulfzType.Alpha);
    }

    /*******************************************************************************
     ***                            Profile Change                               ***
     ********************************************************************************/
    function changeName(uint256 _tokenId, string memory newName)
        public
        override
    {
        require(
            ownerOf(_tokenId) == msg.sender,
            "ChangeName: you're not the owner"
        );
        require(
            !wulfz[_tokenId].bStaked,
            "This Token is already staked. Please try another token."
        );
        _utilityToken.burn(
            msg.sender,
            NAME_CHANGE_PRICE * (10**_utilityToken.decimals())
        );
        super.changeName(_tokenId, newName);
    }

    function changeBio(uint256 _tokenId, string memory _bio) public override {
        require(
            ownerOf(_tokenId) == msg.sender,
            "ChangeBio: you're not the owner"
        );
        _utilityToken.burn(
            msg.sender,
            BIO_CHANGE_PRICE * (10**_utilityToken.decimals())
        );
        super.changeBio(_tokenId, _bio);
    }
}