#!/usr/bin/env python

''' Distribution-based clustering: version 2.0
Accurate method for creating operational taxonomic units (OTUs) from sequence data
Input requirements:
*input files in both OTU by library matrix and alignment files
*parameters such as the distance criteria, pvalue cutoff and abundance criteria that need to be satisfied in order to create an OTU
*output prefix name, such that it will be unique and log and err files can be created (currently only set to stdout)
'''
#needed to parse sequence files and alignments
import Bio
from Bio import AlignIO
import numpy as np
import sys
import argparse
from datetime import datetime
#not sure if all of these things are needed
#somehow need to get chisquare 
import rpy2
import rpy2.robjects as robjects
from rpy2.robjects.packages import importr
base = importr('base')
chisqtest=rpy2.robjects.r("chisq.test")
import gc

#Create custom defs
def hamdist(str1, str2):
   """Count the # of differences between equal length strings str1 and str2"""
   #This doesn't exactly equal the clustalw values
   diffs = 0
   length = 0
   for ch1, ch2 in zip(str1, str2):
      if ch1 != ch2:
         diffs += 1
      if ch1 and ch2 is not '-':
         length += 1
   #divide by the length
   percent=float(diffs)/float(length)
   return percent

def findlowest(str1, str2):
      (aligndist)=hamdist(str1,str2)
      if dounaligned:
         ustr1=str1.replace('-','')
         ustr2=str2.replace('-','')
         (ualigndist)=hamdist(ustr1, ustr2)
         return(min(aligndist,ualigndist))
      else:
         return(aligndist)

def runchisq(i1, i2, OTUarray, reps):
   """Given the index of two ids (existing OTU i1 and candidate i2) and the OTU matrix without headers
   prepare them for chisquare analysis
   This means removing all values that are 0 in both
   running chi2_contingency, getting the residuals
   and testing if they are too small and need to be simulated"""
   #limit to only the two that are tested
   log.write("Starting runchisq with these idexes\n")
   pstring="%d %d\n" % (i1, i2)
   log.write(pstring)
   preparearray=OTUarray[ [i1,i2] ]
   #grab only the columns that have values in either
   testarray=preparearray[:, np.where((preparearray != 0).sum(axis=0) != 0)]
   L=[]
   for i in testarray:
       for j in i:
         for k in j:
            L.append(k)
   #THIS WORKS WITH L!!!!
   pstring=str(L)
   log.write(pstring)
   log.write("\n")

   if len(L):
      if len(L) == 2:
         return(1)
      else:
         m = robjects.r.matrix(robjects.IntVector(L), ncol=2)
         #figure out a way to clear the matrix in case there's an issue
         resnosim= chisqtest(m)
         all=0
         newall=float(all)
         g5=0
         newg5=float(g5)
         for i in range(0,len(resnosim[6])):
            newall+=1
            if i > 5:newg5+=1
            percent=newg5/newall
         if percent < 0.80:
            #check to see if the parent OTU i1 has a stored similated value
            log.write("percent too low, simulate\n")
            res= chisqtest(m,simulate=True, B=reps)
            log.write("Done chisq.test with simulate\n")
            gc.collect()
            return(res[2][0])
         else:
            log.write("Chisq test ok; return nonsim chisq\n")
            gc.collect()
            return(resnosim[2][0])
      
      

def assignOTU(distancecriteria, abundancecriteria, pvaluecutoff, existingOTUalignment, OTUtable1, onlyOTUs, alldata,  x, i):
   """Assign sequence into an existing set of OTUs
   
   distancecriteria, the max distance between sequences that can be merged into an OTU
   abundancecriteria, the fold-difference the existingOTU has to be over the tested OTU to be included
   pvalucutoff, the pvals lower than the cutoff will remain distinct OTUs
   existingOTUalignment, an alignment dataset(?) with only the existing OTUs
   OTUtable1, with only ecological info to pass to pval
   onlyOTUs, with only the OTU names
   all_data, with the sum at the end
   x, the string x=str(alignment[i].seq) from the alignment
   i, the index of the sequence to be worked on which corresponds to OTUtable1, onlyOTUs and alldata"""

   #something about the existingOTUalignment, the OTUtale1 with only ecological info, onlyOTUs with the ids, 
   #the all_data with only the ecological info and the sum at the end
   #the x=str(alignment[0].seq) and the index of the OTU to search for

   #search the existing OTUs for the 10 closests
   pstring="This is the current index: %d\n" % (i) 
   log.write(pstring)
   L=[]
   for y in existingOTUalignment:
      d=findlowest(x, str(y.seq))
      #append this to the current list of close sequences
      if d < distancecriteria:
         L.append((d, y.name))
      
   #sort the list by the first value of the tuple
   sortedL=sorted(sorted(L, key=lambda tup: tup[1]))
   #now the first 10 values will be the ones you want
   #now test whether the distribution or abundance allows merge
   #for all of them change range(0,10) to range(0,len(sortedL))
   upper=len(sortedL)
   for j in range(0,upper):
      #this will be the id of the closest
      #this is the OTU
      OTUid=sortedL[j][1]
      #get the index of the OTUid
      jindex=np.where(onlyOTUs==OTUid)
      actualjindex=jindex[0][0]
      #does it fit the distance criteria
      if sortedL[j][0] < distancecriteria:
         log.write("Passed distance criteria\n")
         #ok to continue
         #does it fit the distance criteria
         if alldata[actualjindex][-1] >= alldata[i][-1]*abundancecriteria:
            log.write("Passed abundance criteria\n")
            #it satisfies the abundance criteria
            #get the pvalue
            pval=runchisq(i, actualjindex, OTUtable1, 10000)
            if pval < pvaluecutoff:
               log.write("Did not pass pvaluecutoff; look for another\n")
               #if it's outside of the cutoff, its significant
               #assign to another 
               #print to log if verbose
               continue
            else:
               log.write("Passed pvalue: merge\n")
               #this is the OTU to merge with
               #print to the log if verbose
               tup=(actualjindex, pval, sortedL[j][0])
               return('merged', tup)
         else:
            #get the next closest one and print to the log if verbose
            #print to log if verbose
            log.write("Did not pass abundance criteria\n")
            continue
      else:
         log.write("Did not pass distance criteria\n")
         tup=('NA', 'NA', 'NA')
         return('not merged', tup)
   else:
      #this will be something to do if you don't find an OTU to merge into
      #not sure if this is necessary
      log.write("Exit without break\n")
      tup=('NA', 'NA', 'NA')
      return('not merged', tup)


def workthroughtable (distancecriteria, abundancecriteria, pvaluecutoff, OTUtable1, OTUtable2, alignment, onlyOTUs):
   log.write("Start workingthroughtable\n")
   new_col = OTUtable1.sum(1)[...,None]
   all_data = np.append(OTUtable1, new_col, 1)

   #this sorts the whole array by the last column, but 
   rsortindex=all_data[:,-1].argsort()

   #now I can work through this from the reverse
   for nindex in reversed(rsortindex):
      log.write("Starting workthough\n")
      #work though the index values from most to least abundant
      #nindex is the index of the next most abundant
      if 'existingOTUalignment' in locals():
         log.write("OTUs exist, assignOTUs\n")
         #OTUs exist, see if it will fit into the existingOTU set
         #this tests both the genetic and ecological similarity
      
         res=assignOTU(distancecriteria, abundancecriteria, pvaluecutoff, existingOTUalignment, OTUtable1, onlyOTUs, all_data, str(alignment[nindex].seq), nindex)
         log.write("Finished assignOTU\n")
         #Work on this, I'm not sure how to do this exactly
         if res[0] == 'merged':
            log.write("The result is merged\n")
            #print out the the log that it's part of the mergeOTU
            pstring="Changefrom,%s,%s,Changeto,p.value,%f,Dist,%f,Done\n" % (onlyOTUs[nindex], onlyOTUs[res[1][0]], res[1][1], res[1][2])
            log.write(pstring)
            listdict[onlyOTUs[res[1][0]]].append(onlyOTUs[nindex])
         else:
            #nothing came back, so create it as a new OTU
            log.write("the result is nothing\n")
            pstring="%s is a parent,Done\n" % (onlyOTUs[nindex])
            log.write(pstring)
            existingOTUalignment.append(alignment[nindex])
            listdict[onlyOTUs[nindex]] = [onlyOTUs[nindex]]
      else:
         #theres nothing to merge with, it's a parent (it's the first one)
         log.write("No OTUs exist, begin\n")
         string="%s is a parent,Done\n" % (onlyOTUs[nindex])
         log.write(string)
         #create the existingOTUalignment to search through
         existingOTUalignment=alignment[nindex:nindex+1]
         listdict[onlyOTUs[nindex]] = [onlyOTUs[nindex]]

if __name__ == '__main__':
   parser = argparse.ArgumentParser(description='Create OTUs using ecological and genetic information (DBC version 2.0)')
   parser.add_argument('OTUtablefile', help='OTU table input')
   parser.add_argument('alignmentfile', help='alignment file input')
   parser.add_argument('outlistfile', help='list output file name')
   parser.add_argument('-o', '--output', default=sys.stdout, type=str, help='output file (default stdout)')
   parser.add_argument('-d', '--dist_cutoff', type=float, default=0.1, help='maximum genetic variation allowed to be within the same population (i.e. OTU)')
   parser.add_argument('-k', '--k_fold', default=0, type=float, help='abundance criteria: existing OTU rep must have at least k-fold increase over the candidate sequence to be joined (use 10 for seq error only)')
   parser.add_argument('-p', '--pvalue', type=float, default=0.0005, help='pvalue cut-off: this could vary depending on the total number of libraries')
   parser.add_argument('-u', '--unaligned', type=str, default=False, help='use the unaligned sequence to correct alignment issues')
   args = parser.parse_args()
   log =open(args.output, 'w')
   timestamp=str(datetime.now())
   string="%s\n" % (timestamp)
   log.write(string)
   log.write("This is a test\n")
   global dounaligned
   dounaligned=args.unaligned
   if 'dounaligned' in globals():
      log.write("yes in global alignment\n")
   else:
      log.write("No unaligned in globals\n")

   if 'dounaligned' in locals():
      log.write("Yes in locals\n")
   else:
      log.write("Not in locals either\n")

   table = np.genfromtxt(args.OTUtablefile, comments="#")
   OTUtable1=table[1:,1:]
   OTUtable2 = np.genfromtxt(args.OTUtablefile, comments="#", names=True, dtype=None)
   alignment = AlignIO.read(args.alignmentfile, "fasta")
   onlyOTUs=OTUtable2['OTU']
   listdict=dict()
   workthroughtable (args.dist_cutoff, args.k_fold, args.pvalue, OTUtable1, OTUtable2, alignment, onlyOTUs)
   log.write("Finished distribution-based clustering\n")
   outlist =open(args.outlistfile, 'w')
   for x in listdict:
      outlist.write("\t".join(listdict[x]))
      outlist.write("\n")

   timestamp=str(datetime.now())
   string="%s\n" % (timestamp)
   log.write(string)   
