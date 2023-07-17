// SPDX-License-Identifier: NONE

//  author Name: Alex Yap
//  author-email: <[email protected]>
//  author-website: https://alexyap.dev

pragma solidity ^0.8.0;

interface INouns3d {
    function balanceN3D(address _user) external view returns(uint256);
}

// Part: OpenZeppelin/[email protected]/Address
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YieldToken is ERC20, Ownable {
    //Start 1641600000 - Sat, January 8, 2022 12:00:00 AM 
    //End   1799280000 - Thu, January 7, 2027 12:00:00 AM, 5 years, 157680000
    uint256 constant public END = 1799280000;
    uint256 constant public BASE_RATE = 10 ether; 

    // max supply 
    uint256 public constant MAX_YIELD_SUPPLY = 135050000 ether;
    uint256 public constant MAX_COMMUNITY_FUND_SUPPLY = 100000000 ether;
    uint256 public constant MAX_PUBLIC_SALES_SUPPLY = 50000000 ether;
    uint256 public constant MAX_TEAM_RESERVE_SUPPLY = 30000000 ether;

    // minted amount
    uint256 public totalYieldSupply;
    uint256 public totalCommunityFundSupply;
    uint256 public totalPublicSalesSupply;
    uint256 public totalTeamReserveSupply;

    mapping(address => bool) councillors;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    INouns3d public nouns3dContract;

    event CouncillorAdded(address councillor);
    event CouncillorRemoved(address councillor);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address _nouns3d) ERC20("NOUN", "NOUN") {
        nouns3dContract = INouns3d(_nouns3d);
        addCouncillor(_nouns3d);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function isCouncillor(address _councillor) public view returns(bool) {
        return councillors[_councillor];
    }

    function addCouncillor(address _councillor) public onlyOwner {
       require(_councillor != address(0), "Cannot add null address");
       councillors[_councillor] = true;
       emit CouncillorAdded(_councillor);
    }

    function removeCouncillor(address _councillor) public onlyOwner {
        require(isCouncillor(_councillor), "Not a councillor");
        delete councillors[_councillor];
        emit CouncillorRemoved(_councillor);
    }

    // updated_amount = (balanceN3D(user) * base_rate * delta / 86400) + amount * initial rate
    function updateRewardOnMint(address _user) external {
        require(councillors[msg.sender], "Unauthorized");

        uint256 time = min(block.timestamp, END);
        uint256 timerUser = lastUpdate[_user];
        uint256 timerRemainder = 0;
        if (timerUser > 0) {
            rewards[_user] = rewards[_user] + (nouns3dContract.balanceN3D(_user) * BASE_RATE * ((time - timerUser) / 86400));
            timerRemainder = (time - timerUser) % 86400;
        } else {
            rewards[_user] = 0;
        }
        
        lastUpdate[_user] = time - timerRemainder;
    }

    // called on transfers
    function updateReward(address _from, address _to, uint256 _tokenId) external {
        require(councillors[msg.sender], "Unauthorized");
        
        if (_tokenId < 7400) {
            uint256 time = min(block.timestamp, END);
            uint256 timerFrom = lastUpdate[_from];
            uint256 timerRemainderFrom = 0;
            
            if (timerFrom > 0) {
                rewards[_from] += nouns3dContract.balanceN3D(_from) * BASE_RATE * ((time - timerFrom) / 86400);
                timerRemainderFrom = (time - timerFrom) % 86400;
            }

            if (timerFrom != END) {
                lastUpdate[_from] = time - timerRemainderFrom;
            }

            if (_to != address(0)) {
                uint256 timerTo = lastUpdate[_to];
                uint256 timerRemainderTo = 0;

                if (timerTo > 0) {
                    rewards[_to] += nouns3dContract.balanceN3D(_to) * BASE_RATE * ((time - timerTo) / 86400);
                    timerRemainderTo = (time - timerTo) % 86400;
                }

                if (timerTo != END) {
                    lastUpdate[_to] = time - timerRemainderTo;
                }
            }
        }
    }

    function getReward(address _to) external {
        require(councillors[msg.sender], "Unauthorized");
        
        uint256 reward = rewards[_to];
        if (reward > 0) {
            require(
                totalYieldSupply + reward <= MAX_YIELD_SUPPLY,
                "Maximum yield supply reached"
            );

            rewards[_to] = 0;
            totalYieldSupply += reward;
            
            _mint(_to, reward);
            emit RewardPaid(_to, reward);
        }
    }

    function communityFundMint(address to, uint256 amount) external {
        require(councillors[msg.sender], "Unauthorized");
        require(
            totalCommunityFundSupply + amount <= MAX_COMMUNITY_FUND_SUPPLY,
            "Maximum community fund supply reached"
        );

        totalCommunityFundSupply += amount;
        _mint(to, amount);
    }

    function publicSalesMint(address to, uint256 amount) external {
        require(councillors[msg.sender], "Unauthorized");
        require(
            totalPublicSalesSupply + amount <= MAX_PUBLIC_SALES_SUPPLY,
            "Maximum public sales supply reached"
        );

        totalPublicSalesSupply += amount;
        _mint(to, amount);
    }

    function teamReserveMint(address to, uint256 amount) external {
        require(councillors[msg.sender], "Unauthorized");
        require(
            totalTeamReserveSupply + amount <= MAX_TEAM_RESERVE_SUPPLY,
            "Maximum team reserve supply reached"
        );

        totalTeamReserveSupply += amount;
        _mint(to, amount);
    }

    function burn(address _from, uint256 _amount) external {
        require(councillors[msg.sender], "Unauthorized");
        
        _burn(_from, _amount);
    }

    function getTotalClaimable(address _user) external view returns(uint256) {
        uint256 time = min(block.timestamp, END);
        uint256 pending = nouns3dContract.balanceN3D(_user) * BASE_RATE * ((time - lastUpdate[_user]) / 86400);
        return rewards[_user] + pending;
    }
}