// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import "./PreSaleBnb.sol";

contract MetaStarterdeployer is ReentrancyGuard {
    using SafeMath for uint256;
    address payable public admin;
    IBEP20 public token;
    IBEP20 public nativetoken;
    address public routerAddress;
    uint256 public _liquiditylockduration;
    uint256 public deploymentFee;
    uint256 public reffee;

    uint256 public adminFeePercent;
    uint256 public reffralPercent;
    uint256 public buybackPercent;

    mapping(address => bool) public isPreSaleExist;
    mapping(address => address) public getPreSale;
    address[] public allPreSales;

    modifier onlyAdmin() {
        require(msg.sender == admin, "MetaStarter: Not an admin");
        _;
    }

    event PreSaleCreated(
        address indexed _token,
        address indexed _preSale,
        uint256 indexed _length
    );

    constructor() {
        admin = payable(0xc1f35dbf9D888D12EA2C7ecF97f3920384149745);
        adminFeePercent = 3;
        reffralPercent = 2;
        buybackPercent = 2;
        _liquiditylockduration = 90 days;
        nativetoken = IBEP20(0xB6e458a408c7EaA4b85529B8e8810991C1931d8d);
        routerAddress = (0x10ED43C718714eb63d5aA57B78B54704E256024E);
        deploymentFee = 0.1 ether;
        reffee = 0.05 ether;
    }

    receive() external payable {}

    function createPreSaleBNB(
        IBEP20 _token,
        address ref,
        uint256 lockduration,
        uint256[9] memory values
    ) external payable isHuman returns (address preSaleContract) {
        require(msg.sender != ref && ref != address(0));
        require(lockduration >= _liquiditylockduration);
        token = _token;
        require(address(token) != address(0), "MetaStarter: ZERO_ADDRESS");
        require(
            isPreSaleExist[address(token)] == false,
            "MetaStarter: PRESALE_EXISTS"
        ); // single check is sufficient
        require(
            msg.value == deploymentFee,
            "MetaStarter: INSUFFICIENT_DEPLOYMENT_FEE"
        );
        admin.transfer(deploymentFee - reffee);
        payable(ref).transfer(reffee);

        bytes memory bytecode = type(preSaleBnb).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token, msg.sender));

        assembly {
            preSaleContract := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }

        IPreSale(preSaleContract).initialize(
            msg.sender,
            token,
            values,
            adminFeePercent,
            reffralPercent,
            buybackPercent,
            routerAddress,
            lockduration,
            nativetoken
        );

        uint256 tokenAmount = getTotalNumberOfTokens(
            values[0],
            values[7],
            values[5],
            values[8]
        );

        tokenAmount = tokenAmount.mul(10**(token.decimals()));
        token.transferFrom(msg.sender, preSaleContract, tokenAmount);
        getPreSale[address(token)] = preSaleContract;
        isPreSaleExist[address(token)] = true; // setting preSale for this token to aviod duplication
        allPreSales.push(preSaleContract);

        emit PreSaleCreated(
            address(token),
            preSaleContract,
            allPreSales.length
        );
    }

    function getTotalNumberOfTokens(
        uint256 _tokenPrice,
        uint256 _listingPrice,
        uint256 _hardCap,
        uint256 _liquidityPercent
    ) public pure returns (uint256) {
        uint256 tokensForSell = _hardCap.mul(_tokenPrice).mul(1000).div(1e18);
        tokensForSell = tokensForSell.add(tokensForSell.mul(2).div(100));
        uint256 tokensForListing = (_hardCap.mul(_liquidityPercent).div(100))
            .mul(_listingPrice)
            .mul(1000)
            .div(1e18);
        return tokensForSell.add(tokensForListing).div(1000);
    }

    function setreffee(uint256 _reffee) external onlyAdmin {
        reffee = _reffee;
    }

    function setdeploymentFee(uint256 _deploymentFee) external onlyAdmin {
        deploymentFee = _deploymentFee;
    }

    function setlockduration(uint256 _duration) external onlyAdmin {
        _liquiditylockduration = _duration;
    }

    function setnativetoken(address _token) external onlyAdmin {
        nativetoken = IBEP20(_token);
    }

    function setAdmin(address payable _admin) external onlyAdmin {
        admin = _admin;
    }

    function setRouterAddress(address _routerAddress) external onlyAdmin {
        routerAddress = _routerAddress;
    }

    function setAdminFeePercent(uint256 _adminFeePercent) external onlyAdmin {
        adminFeePercent = _adminFeePercent;
    }

    function setReffralPercent(uint256 _reffralPercent) external onlyAdmin {
        reffralPercent = _reffralPercent;
    }

    function setBuybackPercent(uint256 _buybackPercent) external onlyAdmin {
        buybackPercent = _buybackPercent;
    }

    function getAllPreSalesLength() external view returns (uint256) {
        if (allPreSales.length == 0) {
            return allPreSales.length;
        } else {
            return allPreSales.length - 1;
        }
    }

    function getAdmin() external view returns (address) {
        return admin;
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }
}