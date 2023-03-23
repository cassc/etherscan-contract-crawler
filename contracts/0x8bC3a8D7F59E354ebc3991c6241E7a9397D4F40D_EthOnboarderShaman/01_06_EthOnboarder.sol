// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

interface IBAAL {
    function mintLoot(address[] calldata to, uint256[] calldata amount) external;
    function mintShares(address[] calldata to, uint256[] calldata amount) external;
    function shamans(address shaman) external returns(uint256);
    function isManager(address shaman) external returns(bool);
    function target() external returns(address);
    function totalSupply() external view returns (uint256);
    function sharesToken() external view returns (address);
    function lootToken() external view returns (address);
}

// tribute eth for loot or shares
contract EthOnboarderShaman is ReentrancyGuard, Initializable {
    uint256 public immutable PERC_POINTS = 1e6;

    event ObReceived(
        address indexed contributorAddress,
        uint256 amount,
        uint256 totalFee,
        uint256 isShares,
        address baal
    );

    uint256 public expiery;
    uint256 public multiply;
    uint256 public minTribute;
    bool public isShares;

    address[] public cuts;
    uint256[] public amounts;

    IBAAL public baal;

    constructor() initializer {}

    function init(
        address _moloch, // DAO address
        uint256 _expiery, // expiery date
        uint256 _multiply, // multiply eth by this
        uint256 _minTribute, // min eth to send
        bool _isShares, // mint shares or loot
        address[] memory _cuts, // addresses to send fees to
        uint256[] memory _amounts // % amount eth to send to each address (1e6)
    ) initializer external {
        require(_cuts.length == _amounts.length, "cuts != amounts");
        baal = IBAAL(_moloch);
        expiery = _expiery;
        multiply = _multiply;
        minTribute = _minTribute;
        isShares = _isShares;
        cuts = _cuts;
        amounts = _amounts;
    }

    function _mintTokens(address to, uint256 amount) private {
        address[] memory _receivers = new address[](1);
        _receivers[0] = to;

        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = amount;

        if (isShares) {
            baal.mintShares(_receivers, _amounts);
        } else {
            baal.mintLoot(_receivers, _amounts);
        }
    }

    // tribute eth for loot or shares
    // must meet minimum tribute
    // fees are sent to the cuts addresses
    // eth is sent to the DAO
    // loot or shares are minted to the sender
    function onboarder() payable public nonReentrant {
        require(address(baal) != address(0), "!init");
        require(expiery > block.timestamp, "expiery");
        require(baal.isManager(address(this)), "Shaman not manager");
        // require(msg.value > PERC_POINTS, "min stake PERC_POINTS");
        require(msg.value >= minTribute, "!minTribute");

        // get total split
        uint256 totalFee = 0;
        // transfer cut to each cut address
        for (uint256 i = 0; i < amounts.length; i++) {
            uint256 _cut = (msg.value / PERC_POINTS) * amounts[i];
            (bool success, ) = cuts[i].call{value: _cut}(
                ""
            );
            require(success, "Transfer to cut failed");
            totalFee = totalFee + _cut;           
        }
        
        // mint loot or shares minus any fees
        uint256 _shares = (msg.value - totalFee) * multiply;

        // send to treasury minus fees
        (bool success2, ) = baal.target().call{value: msg.value - totalFee}(
            ""
        );
        require(success2, "Transfer failed");

        _mintTokens(msg.sender, _shares);

        emit ObReceived(
            msg.sender,
            msg.value,
            totalFee,
            _shares,
            address(baal)
        );
    }

    receive() external payable {
        onboarder();
    }

}

contract EthOnboarderShamanSummoner {
    address payable public template;

    event SummonSimpleOnboarder(
        address indexed baal,
        address onboarder,
        uint256 expiery,
        uint256 multiply,
        uint256 minTribute,
        string details,
        bool _isShares,
        address[] _cuts,
        uint256[] _amounts
    );

    constructor(address payable _template) {
        template = _template;
    }

    function summonOnboarder(
        address _moloch,
        uint256 _expiery,
        uint256 _multiply,
        uint256 _minTribute,
        bool _isShares,
        address[] memory _cuts,
        uint256[] memory _amounts,
        string calldata _details
    ) public returns (address) {
        EthOnboarderShaman onboarder = EthOnboarderShaman(payable(Clones.clone(template)));

        onboarder.init(
            _moloch,
            _expiery,
            _multiply,
            _minTribute,
            _isShares,
            _cuts,
            _amounts    
        );


        emit SummonSimpleOnboarder(
            _moloch,
            address(onboarder),
            _expiery,
            _multiply,
            _minTribute,
            _details,
            _isShares,
            _cuts,
            _amounts 
        );

        return address(onboarder);
    }

}