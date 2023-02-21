pragma solidity ^0.6.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/math/Math.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';


contract MoreAndMore is ERC721,Ownable{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Spirit {
        uint256 typeId;
    }

    Spirit[] public spiritList;


    address public defaultAddress = 0x0000000000000000000000000000000000000000;
    address public walletAddress = 0x56c40D0BdEB806e79F5C03AEa1EC39c170B957B2;

    uint256 public amount = 9999 * 1e18;
    uint256 public maxCount = 158;
    uint256 public maxCount2 = 30;
    uint256 public totalCount = 0;
    uint256 public totalCount2 = 0;

    mapping (address => uint256) public userInfo;

    IERC20 public usdt;


    constructor(address _usdt) public ERC721("More And More", "MAM")
    {
        usdt = IERC20(_usdt);
    }

    function getMaxCount() public view returns(uint256){
        return maxCount;
    }

    function mintNft() public{
        require(maxCount > 0,'is max');
        require(userInfo[msg.sender] == 0,'has nft');
        uint256 amountTl = amount;
        usdt.safeTransferFrom(msg.sender, walletAddress, amountTl);
        uint id = spiritList.length+1;
        spiritList.push(Spirit(
                id
            ));
        _safeMint(msg.sender, id);
        _setTokenURI(id,"https://mam.top/assets/mam.json");
        userInfo[msg.sender] = id;
        totalCount = totalCount.add(1);
        maxCount = maxCount.sub(1);
    }

    function mintNftForLeader(address user) public onlyOwner{
        require(maxCount2 > 0,'is max');
        require(userInfo[user] == 0,'has nft');
        uint id = spiritList.length+1;
        spiritList.push(Spirit(
                id
            ));
        _safeMint(user, id);
        _setTokenURI(id,"https://mam.top/assets/mam.json");
        userInfo[user] = id;
        totalCount2 = totalCount2.add(1);
        maxCount2 = maxCount2.sub(1);
    }

}