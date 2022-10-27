// SPDX-License-Identifier: MIT
/*
                                           .~~~~~~^^^::..                                 
                        .::^~~~^           .!!!!~~~~~~^^^^::..                            
                    .:^^~~~~~!!!.            :::::::::^^^^^^^:::.                         
                ..:^^^^^~~~~~~~.                    :~~~~~^^^^::^~:                       
              .::^^^^^^~~~!!!!!!^                   ~!~~~~^^^^^:::!!:                     
            .:::::^^^~~~~!!!!!!!7:                  :~~~~~^^^^^:::~77~.                   
          .:::::^^^~~~~~~~~!!!!!~.               .::::^^^^^^^^::::!777!:                  
        .:::::^^^^^^~~~~~~~~~~~:                .^^^^^^^:::::::::~777777^                 
       .:::::^^^^^^^^~~~~~^^^^^.                 .::::::::::::::!?7777777^                
      .!::::::^^^^^^^^^^^^^^^^^:       :~^.               ....~7???7777777:               
      ~7^::::::^^^::::::^^:::.       :7JJ?7^               .^7??????777777!.              
     ^7?7^.:::::::::::::..         .!JJJ????!:          .^!?JJ????????7777!~              
    .!7???!^::::::::..           .!JYJJJ???777~.    .:~7JJJJJJJJ????????7!!!:             
    :7????JJ7~^:..              ~JYYJJJ???777!!!~^!?JYYYYJJJJJJJJ??????7!!!!~             
    ^????JJJYYJ?^             ^?YYYJJJJ????JJJYY5555YYYYYYJJJJJJJJJ???7!!!!!!             
    ^????JJJYYY557          :?YYYYJJJJ?JY5555555555YYYYYYYYYJJJJJJJJ?7!!!!!!!.            
    ^7??JJJYYYY55P~        .Y5YYYYJJJ?YPPPP555555555YYYYYYYYYJJJJJ?7777!!!!!~             
    :!7JJJJYYY555P!         .7YYYJJJ?JPPPPPP5555555555YYYYYYYYJJ?7777777!!!!^             
    .!!7?JYYY555PP:           :7YJJ??JPPPPPPPP5555555555YYYYJ?777777777777!~:             
     ~!!!7?YY555Y~              :7J???YPPPPPPPP55555555YJJ?77777777777777!~^.             
     .!!!!!777!^.                 ^7?77J5PPPPPPP55J?????7777777777777777!~~.              
      ^!!!!!777!!~^^:..            .^77777??7!~^:.:7???????77777777777!!~~.               
       ^!!!!7777777?7777!^.          .~77!~.     :??????????77777777!!!!^.                
        :!!77777777777????7^           .^:       :?????????????7!^.~!!~:                  
         .^!!7777777777?????^                     !?????????7!^.   .::                    
          .:^~!!77777777????!                      ^!777!!^:.                             
            .::^^~~!!7777777:                                                             
               ^?JYYY    ^^~7?JJ7 ~?JJY~    ^7?JJ7 .!?JJJJJJJJJJJJ??J?                   
              JBGGPP#P   7GBPP5&[email protected]~  :PG5YY#J!GPYJJJJJJJJ?????75#.                  
             !&P55555#5  BBYYY5&?&5JYJPB   GG?J?J#!&Y?????777777777?YB!                   
             PB5555555#J &5YYYBP?#YYYJ#?  ^&JJJ?PG:PYYYYPB?777YGYYYJ7:                    
            :&P555P5555##BYYYY&!GGYYY5&:  YBJJJ?#7      JB7777#?                          
            ?&5555##5555#PYYYPB!&YYYJGP  .#5JJJY#:     .BY777J#.                          
            BB555P#P#555555YY#YYBYYYY&!  !&JJJ?GP      !#?777G5                           
           ~&P555BP P#55555Y5&!BPYYYP#:. PGJJJJ&!      5G7?7?#~                           
           Y#5P55&! .PB5555YGG!&YYYYPBPPPBYJJJ5#.     :#J7?7YB.                           
          .#G555BB   .GGYYY5&7~&5YYYJJJJJJJJJ?BY      7#777?#J                            
          [email protected]^    B#PGGG?  7GGPPPP55555555&~      GBYY5GJ                             
          ^777!:     .777!~.    .^!77777777777!      .!77!~.                                                                              
*/
pragma solidity >=0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

struct Erc20PaymentInfo {
    bool enabled;
    uint256 perPrice;
    uint256 rewardPrice;
}

struct RewardInfo {
    uint256 totalClaimed;
}

contract NutNFT is ERC721AQueryable, AccessControl, ReentrancyGuard {
    event ReffererRewardEvent(uint256 indexed nftId, address indexed refferer, address indexed rewardToken, uint256 mintAmt, uint256 rewardAmt, string data);
    event SetTokenPayInfoEvent(address indexed token, bool indexed enabled, uint256 price, uint256 reward);
    event ClaimRewardEvent(uint256 indexed nftId, address indexed erc20, address indexed wallet, uint256 amount);
    event SetRewardRootEvent(bytes32 root);

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    uint256 public constant maxTotalSupply = 10000;
    uint256 public startSaleTime = block.timestamp; 
    string public uriPrefix = "";
    string public uriSuffix = ".json";
    bytes32 public rewardMerkleRoot;

    // Erc20Address => TokenID => RewardInfo
    mapping(address => mapping(uint256 => RewardInfo)) public erc20ToNftRewardMap;
    mapping(address => Erc20PaymentInfo) public tokenPayInfo;
    address withdrawOwner;

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Restricted: OnlyAdmin");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "Restricted: OnlyOperator");
        _;
    }

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _uriPrefix
    ) ERC721A(_tokenName, _tokenSymbol) {
        withdrawOwner = _msgSender();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());
        uriPrefix = _uriPrefix;

        setTokenPayInfo(address(0), true, 0.3 ether, 0.1 ether); // address0 = ETH token
        _mint(_msgSender(), 1000);
    }

    /* MINT */
    function mint(uint256 _amt, uint256 _referrerId, string calldata data) external payable nonReentrant {
        Erc20PaymentInfo memory payInfo = tokenPayInfo[address(0)];
        require(_amt > 0, "Invalid mint amount");
        require(payInfo.enabled, "Token is not valid");
        require(block.timestamp > startSaleTime, "Mint is not start");
        require(msg.value >= payInfo.perPrice * _amt, "Insufficient funds");
        require(totalSupply() + _amt <= maxTotalSupply, "Max supply exceeded");

        address referrer = ownerOf(_referrerId);
        require(referrer != address(0), "need enter valid referrer ID");

        uint256 rewards = payInfo.rewardPrice * _amt;
        if(rewards > 0) {
            (bool scc, ) = payable(referrer).call{value: rewards}("");
            require(scc, "cannot pay reward");
        }

        _mint(_msgSender(), _amt);
        emit ReffererRewardEvent(_referrerId, referrer, address(0), _amt, rewards, data);
    }

    function erc20Mint(address _token, uint256 _amt, uint256 _referrerId, string calldata data) external nonReentrant {
        Erc20PaymentInfo memory payInfo = tokenPayInfo[_token];
        require(_amt > 0, "Invalid mint amount");
        require(payInfo.enabled, "Token is not valid");
        require(block.timestamp > startSaleTime, "Mint is not start");
        require(totalSupply() + _amt <= maxTotalSupply, "Max supply exceeded");

        address referrer = ownerOf(_referrerId);
        require(referrer != address(0), "need enter valid referrer ID");

        // receive ERC20
        uint256 rewards = payInfo.rewardPrice * _amt;
        uint256 erc20Cost = payInfo.perPrice * _amt - rewards;
        IERC20 erc20 = IERC20(_token);
        erc20.transferFrom(_msgSender(), withdrawOwner, erc20Cost);
        if(rewards > 0) {
            erc20.transferFrom(_msgSender(), referrer, rewards);
        }

        _mint(_msgSender(), _amt);
        emit ReffererRewardEvent(_referrerId, referrer, _token, _amt, rewards, data);
    }
    
    /* ERC721 */
    function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        string memory uri = super.tokenURI(_tokenId);
        return string(abi.encodePacked(uri, uriSuffix));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function burn(uint256 _tokenId) external {
        _burn(_tokenId, true);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /* REWARD */
    function claimReward(uint256 _claim, uint256 _salt, uint256 _nftId, address _erc20, uint256 _totalReward, bytes32[] calldata proof) external nonReentrant {
        address nftOwner = ownerOf(_nftId);
        require(nftOwner == _msgSender(), "Restricted: only nft owner can claim reward");
        require(checkRewardProof(_salt, _nftId, _erc20, _totalReward, proof), "Restricted: invalid proof");

        erc20ToNftRewardMap[_erc20][_nftId].totalClaimed += _claim;
        uint256 totalClaimed = erc20ToNftRewardMap[_erc20][_nftId].totalClaimed;
        require(totalClaimed <= _totalReward, "No available reward to claim");

        if(_erc20 == address(0)) {
            (bool scc, ) = payable(_msgSender()).call{value: _claim}("");
            require(scc, "cannot pay reward");
        } else {
            IERC20 erc20 = IERC20(_erc20);
            erc20.transfer(_msgSender(), _claim);
        }

        emit ClaimRewardEvent(_nftId, _erc20, _msgSender(), _claim);
    }

    function checkRewardProof(uint256 _salt, uint256 _nftId, address _erc20, uint256 _totalReward, bytes32[] calldata proof) public view returns (bool) {
        require(rewardMerkleRoot != 0, "rewardMerkleRoot cannot be null");
        bytes32 leaf = keccak256(abi.encode(_salt, _nftId, _erc20, _totalReward));
        return MerkleProof.verify(proof, rewardMerkleRoot, leaf);
    }

    /* SETTINGS */
    function setWithdrawOwner(address _addr) external onlyOwner {
        withdrawOwner = _addr;
    }

    function setRewardMerkleRoot(bytes32 _root) external onlyOperator {
        rewardMerkleRoot = _root;
        emit SetRewardRootEvent(_root);
    }

    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setStartSaleTime(uint256 _time) external onlyOwner {
        startSaleTime = _time;
    }

    function withdraw(address _token, uint256 _amt) external onlyOwner {
        if(_token == address(0)) {
            uint256 balance = _amt > 0 ? _amt : address(this).balance;
            (bool sc1, ) = payable(withdrawOwner).call{value: balance * 5 / 10}("");
            require(sc1);
            (bool sc2, ) = payable(_msgSender()).call{value: balance * 5 / 10}("");
            require(sc2);
        } else {
            IERC20 erc20 = IERC20(_token);
            uint256 balance = _amt > 0 ? _amt : erc20.balanceOf(address(this));
            erc20.transfer(_msgSender(), balance);
        }
    }

    function isApprovedForAll(address owner, address operator) public override(ERC721A, IERC721A) view returns (bool) {
        return nftMarketAddress[operator] || super.isApprovedForAll(owner, operator);
    }

    function setTokenPayInfo(address _token, bool _enabled, uint256 _price, uint256 _reward) public onlyOwner {
        tokenPayInfo[_token] = Erc20PaymentInfo(
            _enabled, _price, _reward
        );
        emit SetTokenPayInfoEvent(_token, _enabled, _price, _reward);
    }

    mapping (address => bool) private nftMarketAddress;
    function setNftMarketAddress(address _opensea, bool _enabled) external onlyOwner {
        nftMarketAddress[_opensea] = _enabled;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC721A, AccessControl, ERC721A) returns (bool) {
        return AccessControl.supportsInterface(interfaceId)
            || ERC721A.supportsInterface(interfaceId)
            || super.supportsInterface(interfaceId);
    }

    receive() payable external {}
    fallback() payable external {}
}