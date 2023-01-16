//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./NiftyTicket.sol";
import "./interfaces/INiftyTicket.sol";

import "./interfaces/ISudoSwap.sol";
import "./interfaces/ISudoPair.sol";

import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

contract NiftyLaunch {
    using SafeTransferLib for address payable;

    ISudoSwap public sudoFactory;
    address public erc721Implementation;

    uint256 public nbLaunches;

    mapping(address => address) public launchToOwner;
    mapping(address => address) public launchToSudoPool;
    mapping(address => uint256) public launchExpires;
    mapping(address => uint256) public launchStart;
    mapping(uint256 => address) public launches;

    event Launch(
        address _nftAddress,
        address _sudoPool,
        address indexed _owner
    );

    event LaunchEnd(address indexed _nftAddress);

    constructor(ISudoSwap _sudowswapFactory, address _erc721Implementation) {
        sudoFactory = _sudowswapFactory;
        erc721Implementation = _erc721Implementation;
    }

    function create(
        string memory _ticketName,
        string memory _symbol,
        string memory _baseURI,
        uint256 _maxSupply,
        uint256 _endInTime,
        uint128 _startPrice,
        uint128 _delta,
        uint96 fee,
        address curve
    ) external {
        //deploy NFT contract
        address ticket = cloneTicket(erc721Implementation);

        launchToOwner[ticket] = msg.sender; //store owner
        launchExpires[ticket] = block.timestamp + _endInTime;
        launchStart[ticket] = block.timestamp;

        // create SUDO SWAP POOL
        address sudoPair = sudoFactory.createPairETH(
            IERC721(ticket),
            ICurve(curve),
            payable(0x0), // NOTE from docs: unavailable for Trade pairs.
            LSSVMPair.PoolType.TRADE, // pool type
            _delta, //delta
            fee, //fee
            _startPrice, //starting price in eth
            new uint256[](0)
        );

        //keep track of stuff or frontend
        launchToSudoPool[ticket] = sudoPair;
        launches[nbLaunches] = ticket;
        nbLaunches++;

        //initialize nfts into SUDO SWAP pool
        INiftyTicket(ticket).initialize(
            _ticketName,
            _symbol,
            sudoPair,
            _maxSupply,
            _baseURI
        );

        emit Launch(ticket, sudoPair, msg.sender);
    }

    function finalizeLaunch(address _ticketAddress) external {
        INiftyTicket launch = INiftyTicket(_ticketAddress);
        ISudoPair sudoPool = ISudoPair(launchToSudoPool[_ticketAddress]);

        require(
            block.timestamp > launchExpires[_ticketAddress] ||
                launch.balanceOf(address(sudoPool)) == 0,
            "Sale still active"
        ); //check ending time

        // this withdraws to the contract
        sudoPool.withdrawETH(address(sudoPool).balance); //withdraw all pool balance

        // then sends to the owner of the launch all the eth
        payable(launchToOwner[_ticketAddress]).safeTransferETH(
            address(this).balance
        );

        sudoPool.changeSpotPrice(100 ether); //we set this to 100 ether so no more sales but owner of pool can change later.

        sudoPool.transferOwnership(launchToOwner[_ticketAddress]);

        emit LaunchEnd(address(launch));
    }

    // we only clone contract here and initialize later
    // see: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1167.md
    function cloneTicket(address implementation)
        internal
        returns (address instance)
    {
        bytes20 targetBytes = bytes20(implementation);

        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, clone, 0x37)
        }
    }

    function getLaunchInfos(address _ticketAddress)
        public
        view
        returns (
            uint256 _supply,
            string memory _name,
            string memory _symbol,
            address _sudoPool,
            address _owner,
            uint256 _startTime,
            uint256 _endTime
        )
    {
        INiftyTicket ticket = INiftyTicket(_ticketAddress);

        _supply = ticket.totalSupply();
        _name = ticket.name();
        _symbol = ticket.symbol();

        _sudoPool = launchToSudoPool[_ticketAddress];
        _owner = launchToOwner[_ticketAddress];

        _startTime = launchStart[_ticketAddress];
        _endTime = launchExpires[_ticketAddress];
    }

    receive() external payable {}
}