// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract ZombiePenguins is ERC721Enumerable, IERC721Receiver, Ownable{
    using EnumerableSet for EnumerableSet.UintSet;

    ZombiePenguins public OLDZOMBIE = ZombiePenguins(0x77C76BFB6C2D2fC064a175f325Bb5eCf90789b6e);

    IERC721 public CONTROL = IERC721(address(this));
    IERC20 public TOKEN = IERC20(0x654af6e4fd2d17C475E385750825FBf0a9123509);

    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(uint256 => uint256) public _deposit_blocks;

    string public baseTokenURI;
    uint256 numTokens = 3298;

    bool public onSale = false;
    bool public canStake = false;

    uint256 public price = 0.04 ether;
    uint256 public maxTokensPurchase = 10;
    uint public MAX_TOKEN_SUPPLY = 10000;

    uint256 public RATE = 1562500000000000;
    uint256 public EXPIRATION;

    constructor() ERC721("Zombie Penguins", "ZMBPENGS") {
        baseTokenURI = "ipfs://QmUhuRSaPA8nbgqbeAfagoqSGSGCM1ct9RAsLjEFLGmqZ8/";
        EXPIRATION = block.number + 100000000;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function mint(uint numberOfTokens) external payable {
        require(onSale || msg.sender == owner(), "Not on Sale!");
        require(numberOfTokens <= maxTokensPurchase, "Exceed Max Per");
        require(numTokens + numberOfTokens <= MAX_TOKEN_SUPPLY, "Exceed Max Supply");
        require(msg.value >= (price * numberOfTokens), "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++){
            if (numTokens <= MAX_TOKEN_SUPPLY)
            {
                _safeMint(msg.sender, numTokens + 1);
                numTokens = numTokens + 1;
            }
        }
    }

    //Staking Functions
    function deposit(uint256[] calldata tokenIds) external {
        require(canStake || msg.sender == owner(), "Can not Stake yet!");
        for (uint256 i; i < tokenIds.length; i++) {
            safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ''
            );

            _deposits[msg.sender].add(tokenIds[i]);
            _deposit_blocks[tokenIds[i]] = block.number;
        }
    }

    function withdraw(uint256[] calldata tokenIds) external {
        require(canStake || msg.sender == owner(), "Can not Stake yet!");

        claimRewards();

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                _deposits[msg.sender].contains(tokenIds[i]),
                'Token not deposited'
            );

            _deposits[msg.sender].remove(tokenIds[i]);

            CONTROL.safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                ''
            );
        }
    }

    //Read Functions
    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ids;
    }

    function depositsOf(address account)
        external
        view
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage depositSet = _deposits[account];
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }

        return tokenIds;
    }

    function calculateRewards(address account)
        public
        view
        returns (uint256)
    {
        uint256 rewards = 0;

        EnumerableSet.UintSet storage depositSet = _deposits[account];
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            uint256 tokenId = _deposits[account].at(i);

            rewards = rewards + 
                (
                    RATE *
                    (Math.min(block.number, EXPIRATION) -
                        _deposit_blocks[tokenId])
                );
        }

        return rewards;
    }

    function claimRewards() public {
        uint256 blockNum = Math.min(block.number, EXPIRATION);

        uint256 rewards = calculateRewards(msg.sender);

        uint256 numOfDepositedTokens = _deposits[msg.sender].length();

        for (uint256 i; i < numOfDepositedTokens; i++) {
            uint256 tokenId = _deposits[msg.sender].at(i);

            _deposit_blocks[tokenId] = blockNum;
        }

        if (rewards > 0) {
            try TOKEN.transfer(msg.sender, rewards) returns (bool v) {
            } catch Error(string memory) {}
        }
    }

    function claimNewZombiePenguins(uint256[] calldata tokenIds) public {
        require(canStake || msg.sender == owner(), "Can not Stake yet!");
        require(tokenIds.length > 0, "Must have some tokens to claim");
        require(OLDZOMBIE.isApprovedForAll(msg.sender, address(this)), "Not Approved Yet");

        for(uint256 i = 0; i < tokenIds.length; i++)
        {
            require(OLDZOMBIE.ownerOf(tokenIds[i]) == msg.sender, "You do not own this Penguin");

            OLDZOMBIE.safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ''
            );

            _safeMint(msg.sender, tokenIds[i]);

            _safeMint(msg.sender, tokenIds[i] + 1649);
        }
        
        uint256 rewards = OLDZOMBIE.calculateRewards(msg.sender);

        try TOKEN.transfer(msg.sender, rewards) returns (bool v) {
            } catch Error(string memory) {}
    }   

    //Setter Functions
    function changeOnSale() external onlyOwner(){
        onSale = !onSale;
    }

    function changeCanStake() external onlyOwner(){
        canStake = !canStake;
    }

    function setToken(address _token) external onlyOwner(){
        TOKEN = IERC20(_token);
    }

    function setZombie(address _oldZombie) external onlyOwner(){
        OLDZOMBIE = ZombiePenguins(_oldZombie);
    }

    function setExpiration(uint256 _expiration) external onlyOwner(){
        EXPIRATION = _expiration;
    }

    function setRate(uint256 _rate) external onlyOwner(){
        RATE = _rate;
    }

    //Utilities
    function withdrawAll() external onlyOwner() {
        require(payable(msg.sender).send(address(this).balance));
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}