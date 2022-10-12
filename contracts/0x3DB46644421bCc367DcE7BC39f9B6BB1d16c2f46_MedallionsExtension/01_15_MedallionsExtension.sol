// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";

import "base64-sol/base64.sol";

interface IWETH {
    function deposit() external payable;
}

contract MedallionsExtension is ERC165, ICreatorExtensionTokenURI, ReentrancyGuard {
    using Strings for *;
    
    enum ContractStatus {
        MintPaused,
        MintActive
    }
    
    bool public contractSealed;
    
    uint public constant startingTokenId = 1;
    uint public constant maxSupply = 421;
    uint public constant initialAirdropAmount = 101;
    uint public constant maxPaidMints = maxSupply - initialAirdropAmount;
    
    uint public totalSupply;
    
    address public immutable creator;
    ContractStatus public contractStatus;

    struct TokenInfo {
        uint id;
        string metadata;
        string imageURI;
        uint ethAvailableToWithdraw;
        uint emanationId;
        uint generationNumber;
        bool isEncounter;
        bool isPortrait;
    }
    
    struct ExtraTokenMetadata {
        bool isEncounter;
        bool isPortrait;
    }
    
    mapping(uint => ExtraTokenMetadata) public extraTokenMetadata;
    
    string public baseImageURI = "https://arweave.net/";
    mapping(uint => string) private tokenIdToImageUri;
    string public placeholderImageURI = "saZgtADWl7HbAsCbX9yaEcCtgxfZU8T28hAkiwqVuHk";
    
    uint public allTimeMintProceeds;
    mapping(uint => uint) public tokenEthWithdrawn;
    
    uint public constant middleAdvanceAmount = 20 ether;
    uint public constant middlePct = 10;
    uint public constant middleAdvanceCoveredAt = (middleAdvanceAmount * 100) / middlePct;
    
    uint public amountPaidToMiddle = middleAdvanceAmount;
    address public constant middleAddress = 0xC2172a6315c1D7f6855768F843c420EbB36eDa97;
    address public constant sovAddress = 0x48C4aceED93bC2E40b1790Ce979135982386abc2;
    
    IERC721 public immutable guardians;
    
    event BatchWithdraw(
        address indexed withdrawer,
        uint[] tokenIds,
        uint[] amounts
    );
    
    uint8[99] public guardiansOrderCollected = [36, 52, 89, 29, 85, 27, 70, 77, 9, 56, 41, 69, 18, 3, 59, 72, 83, 79, 63, 28, 44, 61, 26, 88, 81, 95, 10, 99, 74, 4, 20, 48, 93, 6, 91, 66, 58, 38, 19, 21, 12, 92, 49, 17, 25, 47, 35, 7, 78, 51, 96, 67, 73, 39, 62, 43, 22, 84, 46, 16, 42, 30, 82, 8, 32, 80, 45, 15, 68, 86, 87, 97, 14, 13, 54, 23, 11, 2, 5, 65, 34, 60, 50, 71, 33, 40, 57, 24, 64, 55, 90, 94, 75, 76, 98, 37, 31, 53, 1];
    
    function getGuardiansOrderCollected() public view returns (uint8[99] memory) {
        return guardiansOrderCollected;
    }
    
    function tokenShareOfProceeds(uint tokenId) public view returns (uint share) {
        if (tokenId == 1) {
            if (allTimeMintProceeds > middleAdvanceCoveredAt) {
                uint overage = allTimeMintProceeds - middleAdvanceCoveredAt;
                uint base = middleAdvanceCoveredAt;
                uint normalPct = 10;
                uint advancePeriodPct = normalPct + middlePct;
                
                share = (overage * normalPct) / 100 + (base * advancePeriodPct) / 100;
            } else {
                share = (allTimeMintProceeds * 20) / 100;
            }
        } else if (tokenId <= 21) {
            share = (allTimeMintProceeds * 20) / 1000;
        } else if (tokenId <= 101) {
            share = (allTimeMintProceeds * 5) / 1000;
        }
    }
    
    function tokenEthAvailable(uint tokenId) public view returns (uint) {
        return tokenShareOfProceeds(tokenId) - tokenEthWithdrawn[tokenId];
    }
    
    function middleEthAvailable() public view returns (uint) {
        uint middleShareOfProceeds = (allTimeMintProceeds * middlePct) / 100;
        
        return middleShareOfProceeds > amountPaidToMiddle ? middleShareOfProceeds - amountPaidToMiddle : 0;
    }
    
    function middleWithdrawEth() public nonReentrant {
        uint availEth = middleEthAvailable();
        
        require(msg.sender == middleAddress, "Only Middle can withdraw");
        require(availEth > 0, "No ETH available");
        
        amountPaidToMiddle += availEth;
        _safeTransferETHWithFallback(middleAddress, availEth);
    }
    
    function batchTokenEthAvailable(uint[] calldata tokenIds) public view returns (uint amount) {
        for (uint i; i < tokenIds.length; ++i) {
            amount += tokenEthAvailable(tokenIds[i]);
        }
    }
    
    function batchWithdrawTokenProceeds(uint[] calldata tokenIds) public nonReentrant {
        uint amount = batchTokenEthAvailable(tokenIds);
        require(amount > 0, "No ETH available");
        
        uint[] memory amounts = new uint[](tokenIds.length);
        
        for (uint i; i < tokenIds.length; ++i) {
            require(IERC721(creator).ownerOf(tokenIds[i]) == msg.sender, "Only owner can withdraw");
            
            tokenEthWithdrawn[tokenIds[i]] += tokenEthAvailable(tokenIds[i]);
            amounts[i] = tokenEthAvailable(tokenIds[i]);
        }
        
        _safeTransferETHWithFallback(msg.sender, amount);
        
        emit BatchWithdraw(msg.sender, tokenIds, amounts);
    }
    
    constructor(address _creator, address _guardians) {
        creator = _creator;
        guardians = IERC721(_guardians);
    }
    
    function exists(uint tokenId) public view returns (bool ret) {
        try IERC721(creator).ownerOf(tokenId) returns (address) {
            ret = true;
        }
        catch Error(string memory) {}
    }
    
    function totalPaidMints() public view returns (uint) {
        return totalSupply - initialAirdropAmount;
    }
    
    function remainingPaidMints() public view returns (uint) {
        return maxPaidMints - totalPaidMints();
    }
    
    function totalMintCost(uint numTokens) public view returns (uint) {
        uint k = 319 * 320 * 0.102 ether;
        
        uint currentReserve = remainingPaidMints();
        uint newSupply = currentReserve - numTokens;
        
        if (newSupply == 0) {
            return totalMintCost(numTokens - 1) * 3;
        }
        
        return (k / newSupply) - (k / currentReserve);
    }
    
    function mintPublic(uint numTokens) public payable {
        uint costToMint = totalMintCost(numTokens);
        
        require(totalSupply >= initialAirdropAmount, "Airdrop not finished");
        require(msg.sender == tx.origin, "Contracts cannot mint");
        require(contractStatus == ContractStatus.MintActive, "Contract not open for public mint");
        require(msg.value >= costToMint, "Insufficient funds");
        
        _internalMint(msg.sender, numTokens);
        
        allTimeMintProceeds += costToMint;
        
        if (msg.value > costToMint) {
            _safeTransferETHWithFallback(msg.sender, msg.value - costToMint);
        }
    }
    
    function airdropFirstToken() public adminRequired {
        require(totalSupply == 0, "Only works if none have been minted");
        require(Ownable(creator).owner() == msg.sender, "Only owner");

        _internalMint(sovAddress, 1);
    }
    
    function initialAirdrop() public adminRequired {
        require(totalSupply == 1, "Airdrop the first token first");
        require(Ownable(creator).owner() == msg.sender, "Only owner");
        
        for (uint i; i < guardiansOrderCollected.length; ++i) {
            _internalMint(guardians.ownerOf(guardiansOrderCollected[i]), 1);
        }
        
        _internalMint(sovAddress, 1);
    }
    
    function _internalMint(address to, uint numTokens) internal {
        require(numTokens > 0, "Need to mint at least one token");
        require(numTokens + totalSupply <= maxSupply, "Max supply reached");
        
        totalSupply += numTokens;
        IERC721CreatorCore(creator).mintExtensionBatch(to, uint16(numTokens));
    }
    
    function tokenEmanation(uint tokenId) public pure returns (uint) {
        require(tokenId >= startingTokenId && tokenId <= maxSupply, "Token id out of range");
        
        if (tokenId == 1) {
            return 0;
        } else if (tokenId <= 21) {
            return 1;
        } else {
            return (tokenId - 22) / 4 + 2;
        }
    }
    
    function tokenGeneration(uint tokenId) public pure returns (uint) {
        require(tokenId >= startingTokenId && tokenId <= maxSupply, "Token id out of range");
        
        if (tokenId == 1) {
            return 0;
        } else if (tokenId <= 21) {
            return 1;
        } else if (tokenId <= 101) {
            return 2;
        } else {
            return 3;
        }
    }

    function imageURI(uint tokenId) public view returns (string memory) {
        string memory calculatedId = bytes(tokenIdToImageUri[tokenId]).length > 0 ?
                                     tokenIdToImageUri[tokenId] :
                                     placeholderImageURI;
        
        return string.concat(baseImageURI, calculatedId);
    }

    function getTokenInfo(uint tokenId) public view returns (TokenInfo memory) {
        ExtraTokenMetadata memory extraMetadata = extraTokenMetadata[tokenId];
        
        return TokenInfo({
                    id: tokenId,
                    metadata: tokenMetadata(tokenId),
                    imageURI: imageURI(tokenId),
                    ethAvailableToWithdraw: tokenEthAvailable(tokenId),
                    emanationId: tokenEmanation(tokenId),
                    generationNumber: tokenGeneration(tokenId),
                    isEncounter: extraMetadata.isEncounter,
                    isPortrait: extraMetadata.isPortrait
                });
    }
    
    function tokenURI(address _creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        return constructTokenURI(tokenId);
    }
    
    function constructTokenURI(uint tokenId) private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(tokenMetadata(tokenId))
                    )
                )
            );
    }
    
    function tokenWave(uint tokenId) internal pure returns (string memory) {
        if (tokenId == 1 || tokenId >= 22) return '';
        if (tokenId <= 5) return " Wave 1";
        if (tokenId <= 9) return " Wave 2";
        if (tokenId <= 13) return " Wave 3";
        if (tokenId <= 17) return " Wave 4";
        if (tokenId <= 21) return " Wave 5";
        return '';
    }
    
    function tokenMetadata(uint tokenId) public view returns (string memory) {
        require(exists(tokenId), "Token does not exist");
        
        ExtraTokenMetadata memory extraMetadata = extraTokenMetadata[tokenId];
        
        bytes memory title = abi.encodePacked("Medallion ", tokenId.toString());
        string memory tokenDescription = "Gens Guardiana";
        
        string[3] memory optionalAttributes;
        
        if (tokenId != 1) {
            optionalAttributes[0] = string.concat(
                '{'
                    '"trait_type": "EMANATION",'
                    '"value": "Medallion ', tokenEmanation(tokenId).toString(), tokenWave(tokenId), '"'
                '}'
            );
        }
        
        if (extraMetadata.isEncounter) {
            optionalAttributes[1] = string.concat(
                '{'
                    '"trait_type": "ENCOUNTER",'
                    '"value": "Yes"'
                '}'
            );
        }
        
        if (extraMetadata.isPortrait) {
            optionalAttributes[2] = string.concat(
                '{'
                    '"trait_type": "PORTRAIT",'
                    '"value": "Yes"'
                '}'
            );
        }
        
        uint optionalAttributesCount;
        
        for (uint i; i < optionalAttributes.length; ++i) {
            if (bytes(optionalAttributes[i]).length > 0) {
                optionalAttributesCount++;
            }
        }
        
        string memory combinedOptionalAttributes;
        
        for (uint i; i < optionalAttributes.length; ++i) {
            if (bytes(optionalAttributes[i]).length > 0) {
                combinedOptionalAttributes = string.concat(combinedOptionalAttributes, optionalAttributes[i]);
                
                if (i < optionalAttributesCount - 1) {
                    combinedOptionalAttributes = string.concat(combinedOptionalAttributes, ',');
                }
            }
        }
        
        string memory generationString = tokenId == 1 ?
                                         "Genesis" :
                                         string.concat("Gen ", tokenGeneration(tokenId).toString());
        
        return string(
                abi.encodePacked(
                    '{'
                    '"name":"', title, '",'
                    '"description":"', tokenDescription, '",'
                    '"image":"', imageURI(tokenId),'",'
                    '"attributes": ['
                        '{'
                            '"trait_type": "GENERATION",'
                            '"value": "', generationString, '"'
                        '},',
                        combinedOptionalAttributes,
                    ']'
                '}'
                )
            );
    }
    
    function emanationOfNextToken() public view returns (TokenInfo memory) {
        return getTokenInfo(tokenEmanation(nextTokenId()));
    }
    
    function nextTokenId() public view returns (uint) {
        return totalSupply + 1;
    }
    
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        address wethContractAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        
        if (!_safeTransferETH(to, amount)) {
            IWETH(wethContractAddress).deposit{ value: amount }();
            IERC20(wethContractAddress).transfer(to, amount);
        }
    }

    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = payable(to).call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }
    
    function walletOfOwner(address _owner)
        external
        view
        returns (TokenInfo[] memory tokens, uint totalAvailableToWithdraw)
    {
        uint ownerTokenCount = IERC721(creator).balanceOf(_owner);
        tokens = new TokenInfo[](ownerTokenCount);
        
        uint currentTokenId = 1;
        uint ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner;
            
            try IERC721(creator).ownerOf(currentTokenId) returns (address res) {
                currentTokenOwner = res;
            }
            catch Error(string memory) {}
        
            if (currentTokenOwner == _owner) {
                tokens[ownedTokenIndex] = getTokenInfo(currentTokenId);
                
                totalAvailableToWithdraw += tokenEthAvailable(currentTokenId);
                
                ownedTokenIndex++;
            }

            currentTokenId++;
        }
        
        return (tokens, totalAvailableToWithdraw);
    }
    
    function setPlaceholderImageURI(string calldata _placeholderImageURI) public unsealed adminRequired {
        placeholderImageURI = _placeholderImageURI;
    }
    
    function setImageURIs(uint[] calldata tokenIds, string[] calldata arIds) public unsealed adminRequired {
        require(tokenIds.length == arIds.length, "Token ids and ar ids must be same length");
        
        for (uint i; i < tokenIds.length; ++i) {
            require(tokenIds[i] <= maxSupply &&
                    tokenIds[i] >= startingTokenId, "Token id out of range");
            
            tokenIdToImageUri[tokenIds[i]] = arIds[i];
        }
    }
    
    function setExtraTokenMetadata(uint[] calldata tokenIds, ExtraTokenMetadata[] calldata metadata) public unsealed adminRequired {
        require(tokenIds.length == metadata.length, "Token ids and ar ids must be same length");
        
        for (uint i; i < tokenIds.length; ++i) {
            require(tokenIds[i] <= maxSupply &&
                    tokenIds[i] >= startingTokenId, "Token id out of range");
            
            extraTokenMetadata[tokenIds[i]] = metadata[i];
        }
    }
    
    function setContractStatus(ContractStatus status) public adminRequired {
        contractStatus = status;
    }
    
    function setBaseImageURI(string calldata _baseURI) public unsealed adminRequired {
        baseImageURI = _baseURI;
    }
    
    modifier adminRequired() {
        require(
            Ownable(creator).owner() == msg.sender ||
            IAdminControl(creator).isAdmin(msg.sender),
            "AdminControl: Must be owner or admin"
        );
        
        _;
    }
    
    modifier unsealed() {
        require(!contractSealed, "Contract sealed.");
        _;
    }
    
    function sealContract() external adminRequired unsealed {
        contractSealed = true;
    }
    
    function failsafeWithdraw() public adminRequired {
        require(address(this).balance > 0, "Insufficient balance");
        _safeTransferETHWithFallback(Ownable(creator).owner(), address(this).balance);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || super.supportsInterface(interfaceId);

    }
}