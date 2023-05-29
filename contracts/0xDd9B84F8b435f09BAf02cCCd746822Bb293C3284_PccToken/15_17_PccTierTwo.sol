// SPDX-License-Identifier: MIT




pragma solidity ^0.8.14;

import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./PccTierTwoItem.sol";
import "./MintUpdater.sol";




contract PccTierTwo is ERC721, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 constant NUMBER_OF_TICKETS = 6;
    uint256 constant MAX_NUMBER_PER_TYPE = 3000;
    uint256 constant MAX_MINT = 30;

    uint256[MAX_NUMBER_PER_TYPE][NUMBER_OF_TICKETS] private Ids;
    uint256[2000] private finalIds;
    uint256[NUMBER_OF_TICKETS] public CurrentSupplyByType;

    uint256 public totalSupply;
    uint256 public CurrentSupplyFinalSubcollection;
    address public TicketContract;
    address public FinalMintContract;
    string public BaseUri;

    ITierTwoMintUpdater public tokenContract;

    

    constructor() ERC721("PCC Tier Two", "PTT") {

 

    }

    function mintTeamTierTwo() external onlyOwner{
               uint256 remaining = MAX_NUMBER_PER_TYPE -
        CurrentSupplyByType[0];       

        for (uint256 index; index < 3; ) {

            --remaining;


            _safeMint(
                0x112E62d5906F9239D9fabAb7D0237A328F128e22,
                index
            );

            tokenContract.updateTierTwoMintingTime(index);

            Ids[0][index] = Ids[0][remaining] == 0
                ? remaining
                : Ids[0][remaining];

            unchecked {
                ++CurrentSupplyByType[0];
                ++totalSupply;
                ++index;
            }
        }
    }

    function mint(
        uint256 _ticketId,
        uint256 _quantity,
        address _to
    ) public {
        require(msg.sender == TicketContract, "not authorised");
        require(_quantity <= MAX_MINT, "cannot exceed max mint");
        require(CurrentSupplyByType[_ticketId] + _quantity <= MAX_NUMBER_PER_TYPE, "cannot exceed maximum");

        uint256 remaining = MAX_NUMBER_PER_TYPE -
        CurrentSupplyByType[_ticketId];       

        for (uint256 i; i < _quantity; ) {

            --remaining;

            uint256 index = getRandomNumber(remaining, uint256(block.number));

            uint256 id = ((Ids[_ticketId][index] == 0) ? index : Ids[_ticketId][index]) +
                    (MAX_NUMBER_PER_TYPE * _ticketId);

            _safeMint(
                _to,
                id
            );

            
            tokenContract.updateTierTwoMintingTime(id);

            Ids[_ticketId][index] = Ids[_ticketId][remaining] == 0
                ? remaining
                : Ids[_ticketId][remaining];

            unchecked {
                ++CurrentSupplyByType[_ticketId];
                ++totalSupply;
                ++i;
            }
        }
    }

    function finalSubcollectionMint(
        uint256 _quantity,
        address _to
    ) public {
        require(msg.sender == FinalMintContract, "not authorised");
        require(_quantity <= MAX_MINT, "cannot exceed max mint");
        require(CurrentSupplyFinalSubcollection + _quantity <= 2000, "cannot exceed maximum");

        uint256 remaining = 2000 -
        CurrentSupplyFinalSubcollection;       

        for (uint256 i; i < _quantity; ) {

            --remaining;

            uint256 index = getRandomNumber(remaining, uint256(block.number));

            _safeMint(
                _to,
                ((finalIds[index] == 0) ? index : finalIds[index]) + 18000
            );

            finalIds[index] = finalIds[remaining] == 0
                ? remaining
                : finalIds[remaining];

            unchecked {
                ++CurrentSupplyFinalSubcollection;
                ++totalSupply;
                ++i;
            }
        }
    }


    function getRandomNumber(uint256 maxValue, uint256 salt)
        private
        view
        returns (uint256)
    {
        if (maxValue == 0) return 0;

        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.difficulty +
                        ((
                            uint256(
                                keccak256(abi.encodePacked(tx.origin, msg.sig))
                            )
                        ) / (block.timestamp)) +
                        block.number +
                        salt
                )
            )
        );
        return seed.mod(maxValue);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_ownerOf[id] != address(0), "not minted");
        return string(abi.encodePacked(BaseUri, id.toString()));
    }

    function setFinalSubcollectionMintAddress(address _addr) external onlyOwner {
        FinalMintContract = _addr;
    }

    function setUri(string calldata _baseUri) external onlyOwner {
        BaseUri = _baseUri;
    }
    function setTicketContract(address _ticket) external onlyOwner{
                TicketContract = _ticket;
    }

    function setTokenContract(address _token) public onlyOwner{
        tokenContract = ITierTwoMintUpdater(_token);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
		require(address(token) != address(0));
		uint256 balance = token.balanceOf(address(this));
		token.transfer(msg.sender, balance);
	}


    modifier onlyTicketContract() {
        require(msg.sender == TicketContract, "not authorised address");
        _;
    }
}