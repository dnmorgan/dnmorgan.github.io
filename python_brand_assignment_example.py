#Brand assignment using python Example 1. Using least-fill method of assigning brands to survey respondents. 

#Brand 1 object
[chosen_brand_1 if 0] {single} Brand 1
 <1> Brand 1
 <2> Brand 2
 <3> Brand 3
 <4> Brand 4
 <5> Brand 5
 <6> Brand 6
 <7> Brand 7
 <8> Brand 8

#Brand 2 object
[chosen_brand_2 if 0] {single} Brand 2
 <1> Brand 1
 <2> Brand 2
 <3> Brand 3
 <4> Brand 4
 <5> Brand 5
 <6> Brand 6
 <7> Brand 7
 <8> Brand 8

{page least_fill_setup}
{
counter_reset = "1"  # add one to this to reset counter
counter_name = "PROJECT_COUNTRY_DATE_brand_counter_" + counter_reset + str(interview_type)

# first make a list of eligble brands
eligible = int[]
for i in media_aware:
    if i in [1,2,3,5,6]:
        eligible.append(i)

# prioritize 1, then 2,3,5,6
priority1 = int[]
priority2 = int[]
brand_picks = int[]
priority2_brand_counts = int[]


# if there are 1 or 2 eligible brands
if len(eligible) <= 2:
    for i in eligible:
        brand_picks.add(i)

# if there are more than 2 eligible brands
elif len(eligible) > 2:

    # first separate priority vs nonpriority brands
    for i in eligible:
        if i in [1]:
            priority1.append(i)
        elif i in priority_brands:
            priority2.append(i)

    # store the running counts
    #counter_value(c, g):  Returns the value of the counter c within group g
    for i in priority2:
        priority2_brand_counts.append(counter_value(counter_name, i))

    # least fill as needed
    if 1 in priority1:
        brand_picks.add(1)
        if len(priority2) >= 1:
            brand_picks.add(priority2[bottom_n(priority2_brand_counts, 1)[0]])


    #cases that didn't select Brand 1 but have 2+ priority brands
    #bottom_n(l, n)  is a helper function that returns the indices of the first n lowest values in the list l (ties are ignored)
    if len(priority2) >= 2 and len(priority1) == 0:
        brand_picks.add(priority2[bottom_n(priority2_brand_counts, 1)[0]])
        brand_picks.add(priority2[bottom_n(priority2_brand_counts, 2)[1]])


# set singles with the brand selections (randomizing order)
temp brand_picks_rand = random_shuffle(brand_picks)
if len(brand_picks_rand) >= 1:
    chosen_brand_1.set(brand_picks_rand[0])
if len(brand_picks_rand) == 2:
    chosen_brand_2.set(brand_picks_rand[1])
}
{end page least_fill_setup}

#counter_increment(c, g): Increments the value of counter c within group g by 1, returns the new value

{page counter_increment_page}
{
for i in brand_picks:
    counter_increment(counter_name, i)
}
{end page counter_increment_page}

#Example 2 of using python for brand assignment. This method uses a dictionary and random assignment to have the
#end-product of variables be strings.

{page setup_page}
{
temp brand_dict = Dict()
brand_dict[1] = "Brand 1"
brand_dict[2] = "Brand 2"
brand_dict[3] = "Brand 3"
brand_dict[4] = "Brand 4"
brand_dict[5] = "Brand 5"
brand_dict[6] = "Brand 6"
brand_dict[7] = "Brand 7"
brand_dict[8] = "Brand 8"
brand_dict[9] = "Brand 9"
brand_dict[10] = "Brand 10"

#Brand eligibility for questions 8-20:
#Q2 contains all selected brands by survey respondent.
#if Q2 selected ONLY one brand, show brand for Q8-Q20
#if Q2 selected 2 brands ONLY show those 2 brands for Q8-Q20
#if Q2 selected 3 or more brands: if any of the Family brands is selected, show one of these brands, randomize selection if multiple brands selected.


eligbrand_shuffle = int[]
eligbrand_shuffle = random_shuffle(Q2) #Q2 contains all selected brands aware
if 98 in eligbrand_shuffle: #98 = selected 'other brand' option
    eligbrand_shuffle.remove(98)
if 99 in eligbrand_shuffle: #99 = 'none of the above'
    eligbrand_shuffle.remove(99)
if len(eligbrand_shuffle) == 1:
    BRAND1 = brand_dict[eligbrand_shuffle[0]] 
elif len(eligbrand_shuffle) == 2:
    BRAND1 = brand_dict[eligbrand_shuffle[0]] 
    BRAND2 = brand_dict[eligbrand_shuffle[1]] 
elif len(eligbrand_shuffle) > 2:
    temp famArray = []
    temp brandArray = []
    for i in eligbrand_shuffle:
        if i in [4,5,6]:
            famArray.append(i)
        else: 
            brandArray.append(i)
            

    # if they ONLY have [4,5,6] in the eligbrand_shuffle, show 2 of the 3
    if len(famArray) < 1: # no familary brands [4,5,6] aware
        brandArray = random_sample(brandArray,2)
    elif len(famArray) == 3 and len(brandArray) < 1: # ONLY have [4,5,6]
        brandArray.append(famArray[0])
        brandArray.append(famArray[1])
    else: 
        famArray = random_sample(famArray,1)
        brandArray = random_sample(brandArray,1)
        brandArray.append(famArray[0])
        brandArray = random_shuffle(brandArray)
        
    BRAND1 = brand_dict[brandArray[0]]
    BRAND2 = brand_dict[brandArray[1]]
    
}
{end page setup_page}
