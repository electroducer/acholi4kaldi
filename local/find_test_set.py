with open("utt_counts", "r") as cfile:
    counts = [int(line.strip()) for line in cfile]

with open("utt_counts_with_junk", "r") as cfile:
    all_counts = [int(line.strip()) for line in cfile]

matches = 0
for i, a in enumerate(counts):
    print "Trying", i+1
    inner_counts = counts[:]
    del inner_counts[i]
    for j, b in enumerate(inner_counts):
        innest_counts = inner_counts[:]
        del innest_counts[j]
        for k, c in enumerate(innest_counts):
            total = a + b + c
            if (total == 184):
                matches += 1
                print "found", total, i+1, j+1, k+1
            total=0

print matches
