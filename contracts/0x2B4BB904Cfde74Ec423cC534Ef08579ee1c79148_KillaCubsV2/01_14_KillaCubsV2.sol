// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "./KillaCubs/KillaCubsStaking.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract KillaCubsV2 is KillaCubsERC721, IURIManager {
    using Strings for uint256;
    using Strings for uint16;

    constructor(
        address bitsAddress,
        address gearAddress,
        address bearsAddress,
        address passesAddress,
        address kiltonAddress,
        address labsAddress,
        address superOwner
    )
        KillaCubsERC721(
            bitsAddress,
            gearAddress,
            bearsAddress,
            passesAddress,
            kiltonAddress,
            labsAddress,
            superOwner
        )
    {
        uriManager = IURIManager(this);
    }

    function toggleClaims(bool enabled) external onlyOwner {
        claimsStarted = enabled;
    }

    function tokenURI(uint256 id) external view returns (string memory) {
        Token memory token = resolveToken(id);
        return uriManager.getTokenURI(id, token);
    }

    function getTokenURI(
        uint256 id,
        Token memory token
    ) public view returns (string memory) {
        bool staked = token.stakeTimestamp > 0;
        uint256 phase = calculateIncubationPhase(
            token.incubationPhase,
            token.stakeTimestamp,
            token.generation
        );
        uint256 gen = token.generation;
        if (laterGenerations[id] != 0) gen = laterGenerations[id];

        if (staked) {
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        gen == 0 ? "initial-" : "remix-",
                        id.toString(),
                        "-",
                        phase.toString(),
                        "-",
                        token.bit.toString()
                    )
                );
        }

        string storage base = gen > finalizedGeneration || gen == 0
            ? baseURI
            : baseURIFinalized;

        return
            string(
                abi.encodePacked(
                    base,
                    gen == 0 ? "cubryo-" : "cub-",
                    id.toString(),
                    "-",
                    phase.toString()
                )
            );
    }

    function configureRoyalties(
        address royaltyReceiver,
        uint96 royaltyAmount
    ) external onlyOwner {
        _setDefaultRoyalty(royaltyReceiver, royaltyAmount);
    }

    function finalizeGeneration(
        uint256 gen,
        string calldata uri
    ) external onlyOwner {
        finalizedGeneration = gen;
        baseURIFinalized = uri;
    }

    function setURIManager(address addr) external onlyOwner {
        uriManager = IURIManager(addr);
    }

    function setBaseUri(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function copyTokensClaimed(address, uint256, uint256) external onlyOwner {
        (bool success, ) = _delegatecall(airdropper, msg.data);
        require(success, "delegatecall failed");
    }

    function copyTokensBatched(address, uint256, uint256) external onlyOwner {
        (bool success, ) = _delegatecall(airdropper, msg.data);
        require(success, "delegatecall failed");
    }

    function stake(uint256[] calldata) external {
        (bool success, ) = _delegatecall(staker, msg.data);
        require(success, "delegatecall failed");
    }

    function unstake(uint256[] calldata, bool) external {
        (bool success, ) = _delegatecall(staker, msg.data);
        require(success, "delegatecall failed");
    }

    function addBits(uint256[] calldata, uint16[] calldata) external {
        (bool success, ) = _delegatecall(staker, msg.data);
        require(success, "delegatecall failed");
    }

    function removeBits(uint256[] calldata) external {
        (bool success, ) = _delegatecall(staker, msg.data);
        require(success, "delegatecall failed");
    }

    function extractGear(uint256[] calldata) external {
        (bool success, ) = _delegatecall(staker, msg.data);
        require(success, "delegatecall failed");
    }

    function fastForward(
        address,
        uint256[] calldata,
        uint256
    ) external onlyAuthority {
        (bool success, ) = _delegatecall(staker, msg.data);
        require(success, "delegatecall failed");
    }

    function configureStakingWindows(uint256, uint256) external onlyOwner {
        (bool success, ) = _delegatecall(staker, msg.data);
        require(success, "delegatecall failed");
    }

    function setIncubator(address) external onlyOwner {
        (bool success, ) = _delegatecall(staker, msg.data);
        require(success, "delegatecall failed");
    }

    function startNexGeneration() external onlyOwner {
        (bool success, ) = _delegatecall(staker, msg.data);
        require(success, "delegatecall failed");
    }

    function claim(uint256[] calldata, bool) public {
        (bool success, ) = _delegatecall(claimer, msg.data);
        require(success, "delegatecall failed");
    }

    function redeem(uint16, bool) external {
        (bool success, ) = _delegatecall(claimer, msg.data);
        require(success, "delegatecall failed");
    }

    fallback() external payable {
        address extension = extensions[msg.sig];
        require(extension != address(0));
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                extension,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}