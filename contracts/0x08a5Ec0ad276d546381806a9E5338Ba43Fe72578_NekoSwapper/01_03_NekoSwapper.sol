// author: SRB
pragma solidity 0.8.16;
import "@openzeppelin/contracts/access/Ownable.sol";

interface INekoNation {
    function MAX_SUPPLY() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function devMint(address to, uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract NekoSwapper is Ownable {
    address public constant NekonationContractAddress =
        0x660e8ac72dd2C4b69FbeFD0C89824C7E0a88e8A2;
    bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT");
    uint256 public swapTimeThreshold = 69 minutes;
    uint256 public swapFee = 0 ether;
    mapping(uint256 => uint256) public lastSwapTimeOfTokenId;

    INekoNation NekonationContract = INekoNation(NekonationContractAddress);

    function changeSwapFee(uint256 newSwapFee) external onlyOwner {
        swapFee = newSwapFee;
    }

    function changeSwapTimeThreshold(uint256 newSwapTimeThreshold)
        external
        onlyOwner
    {
        swapTimeThreshold = newSwapTimeThreshold;
    }

    function contractHasSupportRole() public view returns (bool) {
        return NekonationContract.hasRole(SUPPORT_ROLE, address(this));
    }

    function contractHasApproval() public view returns (bool) {
        return NekonationContract.isApprovedForAll(msg.sender, address(this));
    }

    function getTokenIDsTimes(uint256[] memory usersTokenIDsArray)
        external
        view
        returns (uint256[] memory)
    {
        uint256 resLength = usersTokenIDsArray.length;
        uint256[] memory tokenIDsTimes = new uint256[](resLength);
        for (uint256 i = 0; i < resLength; i++) {
            tokenIDsTimes[i] = lastSwapTimeOfTokenId[usersTokenIDsArray[i]];
        }
        return tokenIDsTimes;
    }

    /// @notice Swaps old NekoNation NFT for new one until supply max is reached
    /// @dev requires SUPPORT role granted to contract address,
    ///      requires Approval of msg.sender to transfer his token
    ///      this SC holds the transfered old Token, since burning is not possible
    /// @param oldTokenIds array of tokenIds that you want to swap for new ones
    function swap(uint256[] memory oldTokenIds) external payable {
        // contract checks
        require(contractHasApproval(), "approval to contract missing");
        require(
            NekonationContract.hasRole(SUPPORT_ROLE, address(this)),
            "Support Role to contract missing"
        );
        // check ownership
        require(
            tokenIDsOwnershipValid(oldTokenIds),
            "msg.sender not owner of all oldTokenIds"
        );

        // amount check
        uint256 tokenAmount = oldTokenIds.length;
        require(
            tokenAmount > 0 && tokenAmount <= 20,
            "incorrect amount of oldTokenIds"
        );
        // check swap Time
        require(tokenIDsTimeCanSwap(oldTokenIds), "tokenId cannot swap yet");
        // check correct payment
        require(msg.value >= swapFee * tokenAmount, "price not paid");

        uint256 currentSupply = NekonationContract.totalSupply();
        // check if tokenAmount exceeds MAX_SUPPLY
        require(
            currentSupply + tokenAmount <= NekonationContract.MAX_SUPPLY(),
            "maxSupply reached"
        );

        for (uint256 i = 0; i < oldTokenIds.length; i++) {
            // collect users old tokens
            NekonationContract.transferFrom(
                msg.sender,
                address(this),
                oldTokenIds[i]
            );
            // block swap for the new tokens
            uint256 futureTokenId = currentSupply + i;
            lastSwapTimeOfTokenId[futureTokenId] = block.timestamp;
        }
        // mint new tokens to user
        NekonationContract.devMint(msg.sender, tokenAmount);
    }

    function tokenIDsOwnershipValid(uint256[] memory tokenIds)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (NekonationContract.ownerOf(tokenIds[i]) != msg.sender) {
                return false;
            }
        }
        return true;
    }

    function tokenIDsTimeCanSwap(uint256[] memory tokenIds)
        public
        view
        returns (bool)
    {
        uint256 currentTime = block.timestamp;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (
                lastSwapTimeOfTokenId[tokenIds[i]] + swapTimeThreshold >
                currentTime
            ) {
                return false;
            }
        }
        return true;
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = NekonationContract.balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;
        uint256 maxSupply = NekonationContract.totalSupply();
        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = NekonationContract.ownerOf(
                currentTokenId
            );
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function withdrawETH() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "tx failed");
    }
}