//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library Randomizer
{
    event Divine(uint32 indexed tokenID, uint32 indexed index, uint32 indexed divineType, uint32 oldValue, uint32 newValue);

    struct RandomData
    {
        uint256 min;
        uint256 max;
        uint256 randomCap;
    }

    // LCG of MMIX by Donald Knuth
    function getNextRandom(uint256 randomNumber) public pure returns(uint256)
    {
        unchecked
        {
            return ((6364136223846793005 * randomNumber + 1442695040888963407) & 18446744073709551615) >> 3;
        }
    }

    function getMintValues(uint256 randomNumber) external pure returns(uint32[8] memory, uint32[8] memory, uint256)
    {
        unchecked
        {
            uint32[8] memory mask;
            uint256 majorsCount;

            {
                uint256[] memory majorProbabilities = new uint256[](3);
                majorProbabilities[0] = 1000;
                majorProbabilities[1] = 400;
                majorProbabilities[2] = 100;

                uint256[] memory majorsMaskOrder = new uint256[](3);
                majorsMaskOrder[0] = 0;
                majorsMaskOrder[1] = 1;
                majorsMaskOrder[2] = 2;

                majorsMaskOrder = shuffleArray(randomNumber, majorsMaskOrder);

                uint256 isGameBonusChanceIncreased;
                for (uint256 i = 0; i < 3; ++i)
                {
                    uint256 maskValue = randomNumber % 1000 <= majorProbabilities[majorsCount] ? 1 : 0;
                    if (maskValue == 0)
                    {
                        break;
                    }

                    if (i == 1 && isGameBonusChanceIncreased == 1 && majorsMaskOrder[i] != 2)
                    {
                        if (randomNumber % 2 == 0)
                        {
                            majorsMaskOrder[i + 1] = majorsMaskOrder[i];
                            majorsMaskOrder[i] = 2;
                        }
                    }

                    mask[majorsMaskOrder[i]] = uint32(maskValue);
                    
                    if (i == 0 && majorsMaskOrder[i] != 2)
                    {
                        isGameBonusChanceIncreased = 1;
                    }
                    else
                    {
                        isGameBonusChanceIncreased = 0;
                    }

                    ++majorsCount;

                    randomNumber = getNextRandom(randomNumber);
                }
            }

            randomNumber = getNextRandom(randomNumber);

            {
                uint256[] memory minorProbabilities = new uint256[](4);
                minorProbabilities[0] = 700;
                minorProbabilities[1] = 350;
                minorProbabilities[2] = 150;
                minorProbabilities[3] = 50;

                uint256[] memory minorsMaskOrder = new uint256[](4);
                minorsMaskOrder[0] = 3;
                minorsMaskOrder[1] = 4;
                minorsMaskOrder[2] = 5;
                minorsMaskOrder[3] = 6;

                minorsMaskOrder = shuffleArray(randomNumber, minorsMaskOrder);

                uint256 minorsCount;
                for (uint256 i = 0; i < 4; ++i)
                {
                    uint256 maskValue = randomNumber % 1000 <= minorProbabilities[minorsCount] ? 1 : 0;
                    if (maskValue == 0)
                    {
                        break;
                    }

                    mask[minorsMaskOrder[i]] = uint32(maskValue);
                    ++minorsCount;

                    randomNumber = getNextRandom(randomNumber);
                }
            }

            randomNumber = getNextRandom(randomNumber);

            (uint32[8] memory values) = finalizeGettingMintValues(randomNumber, mask);

            {
                if (majorsCount == 3 && randomNumber % 100 < 20)
                {
                    majorsCount = 4;
                }
            }

            return (mask, values, majorsCount);
        }
    }

    function finalizeGettingMintValues(uint256 randomNumber, uint32[8] memory mask) public pure returns (uint32[8] memory)
    {
        unchecked
        {
            RandomData[][] memory randomization = getRandomization();

            uint32[8] memory values;
            for (uint256 i = 0; i < 7; ++i)
            {
                if (mask[i] == 1)
                {
                    uint256 randomRoll = randomNumber % 1000;
                    uint256 length = randomization[i].length;
                    for (uint256 j = 0; j < length; ++j)
                    {
                        if (randomRoll <= randomization[i][j].randomCap)
                        {
                            values[i] = uint32(randomization[i][j].min + randomNumber % (randomization[i][j].max - randomization[i][j].min));
                            randomNumber -= values[i];
                            break;
                        }
                    }
                }
            }

            return (values);
        }
    }

    function getUpgradeValue(uint256 randomNumber, uint32[8] memory modifiers, uint256 runeType, uint256 isAddingNewStat) external pure returns(uint256, uint32)
    {
        uint256[] memory indexes;
        if (runeType == 0)
        {
            indexes = new uint256[](4);
            indexes[0] = 3;
            indexes[1] = 4;
            indexes[2] = 5;
            indexes[3] = 6;
        }
        else
        {
            if (isAddingNewStat == 1)
            {
                if (modifiers[2] == 0 && (modifiers[0] == 0 || modifiers[1] == 0))
                {
                    indexes = new uint256[](4);
                    indexes[0] = 0;
                    indexes[1] = 1;
                    indexes[2] = 2;
                    indexes[3] = 2;
                }
                else
                {
                    indexes = new uint256[](3);
                    indexes[0] = 0;
                    indexes[1] = 1;
                    indexes[2] = 2;
                }
            }
            else
            {
                indexes = new uint256[](2);
                indexes[0] = 0;
                indexes[1] = 1;
            }
        }

        indexes = shuffleArray(randomNumber, indexes);

        unchecked
        {
            for (uint256 i = 0; i < indexes.length; ++i)
            {
                if ((modifiers[indexes[i]] == 0 && isAddingNewStat == 1) || (modifiers[indexes[i]] != 0 && isAddingNewStat == 0))
                {
                    return (indexes[i], getValue(randomNumber, indexes[i]));
                }
            }
        }

        return (0, 0);
    }

    function getValue(uint256 randomNumber, uint256 index) public pure returns(uint32)
    {
        RandomData[] memory randomData;
        if (index == 0)
        {
            randomData = new RandomData[](6);
            randomData[0] = RandomData(100, 250, 10);
            randomData[1] = RandomData(80, 100, 100);
            randomData[2] = RandomData(60, 80, 250);
            randomData[3] = RandomData(40, 60, 450);
            randomData[4] = RandomData(20, 40, 700);
            randomData[5] = RandomData(10, 20, 999);
        }
        else if (index == 1)
        {
            randomData = new RandomData[](6);
            randomData[0] = RandomData(100000, 150000, 10);
            randomData[1] = RandomData(80000, 100000, 100);
            randomData[2] = RandomData(60000, 80000, 250);
            randomData[3] = RandomData(40000, 60000, 450);
            randomData[4] = RandomData(20000, 40000, 700);
            randomData[5] = RandomData(10000, 20000, 999);
        }
        else if (index == 2)
        {
            randomData = new RandomData[](1);
            randomData[0] = RandomData(1, 999, 999);
        }
        else if (index == 3)
        {
            randomData = new RandomData[](4);
            randomData[0] = RandomData(200, 300, 50);
            randomData[1] = RandomData(150, 200, 150);
            randomData[2] = RandomData(100, 150, 500);
            randomData[3] = RandomData(10, 100, 999);
        }
        else if (index == 4)
        {
            randomData = new RandomData[](5);
            randomData[0] = RandomData(100, 300, 10);
            randomData[1] = RandomData(80, 100, 100);
            randomData[2] = RandomData(60, 80, 300);
            randomData[3] = RandomData(40, 60, 600);
            randomData[4] = RandomData(10, 40, 999);
        }
        else if (index == 5)
        {
            randomData = new RandomData[](6);
            randomData[0] = RandomData(500, 1000, 10);
            randomData[1] = RandomData(400, 500, 100);
            randomData[2] = RandomData(300, 400, 250);
            randomData[3] = RandomData(200, 300, 450);
            randomData[4] = RandomData(100, 200, 700);
            randomData[5] = RandomData(10, 100, 999);
        }
        else if (index == 6)
        {
            randomData = new RandomData[](5);
            randomData[0] = RandomData(4000, 5000, 50);
            randomData[1] = RandomData(3000, 4000, 150);
            randomData[2] = RandomData(2000, 3000, 350);
            randomData[3] = RandomData(1000, 2000, 600);
            randomData[4] = RandomData(100, 1000, 999);
        }

        unchecked
        {
            uint256 randomRoll = randomNumber % 1000;
            uint256 length = randomData.length;
            for (uint256 i = 0; i < length; ++i)
            {
                if (randomRoll <= randomData[i].randomCap)
                {
                    return uint32(randomData[i].min + randomNumber % (randomData[i].max - randomData[i].min));
                }
            }
        }

        return uint32(randomData[0].min);
    }

    function divine(uint256 randomNumber, uint32[8] memory modifiers, uint32 tokenID, uint32 amount) external returns(uint32[8] memory)
    {
        uint32[8] memory minValues = [uint32(10), 10000, 0, 10, 10, 10, 100, 0];
        uint32[8] memory maxValues = [uint32(100), 100000, 0, 300, 100, 500, 5000, 0];
        uint32[8] memory maxBoostedValues = [uint32(250), 150000, 0, 300, 300, 1000, 5000, 0];

        unchecked
        {
            uint256 attributesAmount;
            if (modifiers[0] > 0) { ++attributesAmount; }
            if (modifiers[1] > 0) { ++attributesAmount; }
            if (modifiers[3] > 0) { ++attributesAmount; }
            if (modifiers[4] > 0) { ++attributesAmount; }
            if (modifiers[5] > 0) { ++attributesAmount; }
            if (modifiers[6] > 0) { ++attributesAmount; }

            if (attributesAmount == 0)
            {
                return modifiers;
            }

            uint256[] memory indexes = new uint256[](attributesAmount);
            uint256 currentAttrIndex = 0;
            for (uint256 i = 0; i < 7; ++i)
            {
                if (modifiers[i] > 0 && i != 2)
                {
                    indexes[currentAttrIndex++] = i;
                }
            }

            for (uint32 i = 0; i < amount; ++i)
            {
                uint256 attrIndex = indexes[randomNumber % attributesAmount];

                randomNumber = getNextRandom(randomNumber);

                uint32 change = uint32(maxValues[attrIndex] * (randomNumber % 1001 + 500) / 10000);

                randomNumber = getNextRandom(randomNumber);

                uint32 oldValue = modifiers[attrIndex];

                if ((randomNumber % 2 == 0 || modifiers[attrIndex] == maxBoostedValues[attrIndex]) && modifiers[attrIndex] != minValues[attrIndex])
                {
                    if (change > modifiers[attrIndex] || modifiers[attrIndex] - change < minValues[attrIndex])
                    {
                        modifiers[attrIndex] = minValues[attrIndex];
                    }
                    else
                    {
                        modifiers[attrIndex] -= change;
                    }
                }
                else
                {
                    if (modifiers[attrIndex] > maxBoostedValues[attrIndex] - change)
                    {
                        modifiers[attrIndex] = maxBoostedValues[attrIndex];
                    }
                    else
                    {
                        modifiers[attrIndex] += change;
                    }
                }

                emit Divine(tokenID, uint32(attrIndex), 0, oldValue, modifiers[attrIndex]);
            }

            return modifiers;
        }
    }

    function getRandomization() public pure returns(RandomData[][] memory)
    {
        unchecked
        {
            RandomData[][] memory randomization = new RandomData[][](7);

            RandomData[] memory temp = new RandomData[](6);
            temp[0] = RandomData(100, 250, 10);
            temp[1] = RandomData(80, 100, 100);
            temp[2] = RandomData(60, 80, 250);
            temp[3] = RandomData(40, 60, 450);
            temp[4] = RandomData(20, 40, 700);
            temp[5] = RandomData(10, 20, 999);

            randomization[0] = temp;

            temp = new RandomData[](6);
            temp[0] = RandomData(100000, 150000, 10);
            temp[1] = RandomData(80000, 100000, 100);
            temp[2] = RandomData(60000, 80000, 250);
            temp[3] = RandomData(40000, 60000, 450);
            temp[4] = RandomData(20000, 40000, 700);
            temp[5] = RandomData(10000, 20000, 999);

            randomization[1] = temp;

            temp = new RandomData[](1);
            temp[0] = RandomData(1, 999, 999);

            randomization[2] = temp;

            temp = new RandomData[](4);
            temp[0] = RandomData(200, 300, 50);
            temp[1] = RandomData(150, 200, 150);
            temp[2] = RandomData(100, 150, 500);
            temp[3] = RandomData(10, 100, 999);

            randomization[3] = temp;
            
            temp = new RandomData[](5);
            temp[0] = RandomData(100, 300, 10);
            temp[1] = RandomData(80, 100, 100);
            temp[2] = RandomData(60, 80, 300);
            temp[3] = RandomData(40, 60, 600);
            temp[4] = RandomData(10, 40, 999);

            randomization[4] = temp;

            temp = new RandomData[](6);
            temp[0] = RandomData(500, 1000, 10);
            temp[1] = RandomData(400, 500, 100);
            temp[2] = RandomData(300, 400, 250);
            temp[3] = RandomData(200, 300, 450);
            temp[4] = RandomData(100, 200, 700);
            temp[5] = RandomData(10, 100, 999);

            randomization[5] = temp;

            temp = new RandomData[](5);
            temp[0] = RandomData(4000, 5000, 50);
            temp[1] = RandomData(3000, 4000, 150);
            temp[2] = RandomData(2000, 3000, 350);
            temp[3] = RandomData(1000, 2000, 600);
            temp[4] = RandomData(100, 1000, 999);

            randomization[6] = temp;

            return randomization;
        }
    }

    function shuffleArray(uint256 randomNumber, uint256[] memory array) public pure returns(uint256[] memory)
    {
        unchecked
        {
            uint256 length = array.length;
            for (uint256 i = 0; i < length; ++i)
            {
                uint256 n = i + randomNumber % (length - i);
                uint256 temp = array[n];
                array[n] = array[i];
                array[i] = temp;
            }

            return array;
        }
    }
}