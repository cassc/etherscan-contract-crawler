// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IPepeEditor {
    function getCustomTraitBundleForLayers(uint256 tokenId) external view returns (bytes[4] memory);
}

import "@openzeppelin/contracts/access/Ownable.sol";

contract BundleManager is Ownable {

    address public _pepeEditorAddress;

    uint16[1] public _backSlots = [335];

    uint16[2] public _frontSlots = [754, 1135];

    uint16[6] public _backgroundSlots = [131, 2791, 2923, 3056, 3187, 3320];

    uint16[7] public _one_oneIds = [2686, 5213, 7203, 10557, 12886, 15563, 18387];

    uint16[7] public _one_oneSlots = [3515, 15950, 19120, 23413, 24920, 28426, 31833];

    uint16[67] public _faceSlots = [607, 1041, 1622, 2155, 2615, 2928, 3308, 3610, 4021, 4410, 4664, 5096, 5390, 5753, 6208, 6680, 7249, 7646, 8063, 8480, 8750, 9375, 9742, 10123, 10542, 10974, 11360, 11863, 12363, 12748, 13139, 13846, 14339, 14750, 15158, 15549, 15969, 16359, 16789, 17308, 17707, 18108, 18476, 18864, 19220, 19904, 20564, 21129, 21893, 22313, 22889, 23331, 23657, 24143, 24609, 25035, 25405, 25845, 26411, 26712, 27107, 27480, 27966, 28628, 29056, 29576, 30020];

    uint24[93] public _bodySlots = [973, 1891, 3050, 4030, 5010, 6014, 6844, 7742, 8632, 9376, 10147, 10918, 11827, 12654, 13546, 14359, 15129, 16017, 16969, 17892, 18771, 19565, 20433, 21234, 22077, 23020, 23741, 24524, 25342, 26355, 27135, 27971, 28841, 29734, 30609, 31654, 32604, 33466, 34299, 35159, 36138, 37099, 37999, 38918, 40078, 40999, 41771, 42460, 43356, 44325, 45068, 45928, 46757, 47640, 48652, 49567, 50338, 51206, 52125, 53089, 53904, 54755, 55773, 56643, 57485, 58307, 59350, 60265, 61091, 61833, 62652, 63517, 64342, 65264, 66161, 67039, 67819, 68788, 69593, 70355, 71143, 71984, 72770, 73687, 74480, 75323, 76139, 76947, 77801, 78671, 79697, 80751, 81661];

    uint24[99] public _hatSlots = [447, 893, 1401, 1909, 2859, 3184, 3616, 4101, 4809, 5362, 5867, 6175, 6637, 7103, 7580, 8030, 8765, 9220, 9672, 10281, 10570, 11325, 11722, 12551, 12970, 13473, 14523, 14988, 15304, 15417, 15967, 16528, 17004, 17483, 17973, 18474, 18921, 19550, 20041, 20820, 21220, 21541, 21989, 22964, 23736, 24090, 25052, 25354, 25825, 26226, 26747, 27274, 27718, 28557, 29253, 29764, 30132, 30503, 31216, 32052, 32565, 33081, 33542, 33997, 34377, 34829, 35402, 36077, 36528, 37205, 37846, 38228, 38731, 39037, 39507, 40484, 41223, 41752, 42174, 42663, 43264, 43695, 44451, 44980, 45485, 45993, 46414, 47521, 47916, 48416, 49101, 49546, 50123, 50607, 51064, 51654, 52120, 52577, 53119];

    // 0: bg
    // 1: back
    // 2: body
    // 3: hat
    // 4: face
    // 5: front
    // 6: 1_1
    uint24[7] public _layerByteBoundaries = [3320, 3655, 85316, 138435, 168455, 169590, 201423];

    uint8[] public _faceMaskingList = [39];

    /**
     🐸 @notice Get the full face masking list
     🐸 @return face_masking_list as uint8 array
     */
    function getFaceMaskingList() external view returns (uint8[] memory) {
        return _faceMaskingList;
    }

    /**
     🐸 @notice Add a trait id to face masking list
     🐸 @param traitId - Unique id related to a trait for the face layer
     */
    function addFaceToMaskingList(uint8 traitId) external onlyOwner {
        _faceMaskingList.push(traitId);
    }

    /**
     🐸 @notice Edit face mask list by index
     🐸 @param index - Index of array value to edit
     🐸 @param traitId - Value to enter
     */
    function editFaceToMaskingListEntry(uint256 index, uint8 traitId) external onlyOwner {
        _faceMaskingList[index] = traitId;
    }

    /**
     🐸 @notice Delete face mask list by index
     🐸 @param index - Index of array value to delete
     */
    function deleteFaceToMaskingListEntry(uint256 index) external onlyOwner {
        _faceMaskingList[index] = _faceMaskingList[_faceMaskingList.length - 1];
        _faceMaskingList.pop();
    }

    /**
     🐸 @notice Get full array of 1/1 ids
     */
    function getOneOfOneList() external view returns (uint16[7] memory) {
        return _one_oneIds;
    }

    /**
     🐸 @notice Get full array of layer bytes boundaries
     */
    function getLayerByteBoundaries() external view returns (uint24[7] memory) {
        return _layerByteBoundaries;
    }

    /**
     🐸 @notice Get any custom trait bundle for layers
     🐸 @param tokenId - Token to get data for
     🐸 @return data - Array of custom trait bundles for all layers for desired token
     */
    function getCustomTraitBundleForLayers(uint256 tokenId) external view returns (bytes[4] memory data) {
        address pepeEditorAddress = _pepeEditorAddress;
        if (pepeEditorAddress != address(0)) {
            IPepeEditor pepeEditor = IPepeEditor(pepeEditorAddress);
            data = pepeEditor.getCustomTraitBundleForLayers(tokenId);
        }
    }

    /**
     🐸 @notice Set address of Pepe Editor
     🐸 @param pepeEditorAddress - Address of contract
     */
    function setPepeEditorAddress(address pepeEditorAddress) external onlyOwner {
        _pepeEditorAddress = pepeEditorAddress;
    }
}